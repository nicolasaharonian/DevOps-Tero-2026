"""Lambda de notificaciones de Tero.

Recibe mensajes del topic SNS "tero-alertas", los pasa en limpio y los
publica en el topic "tero-notificaciones-mail", que los manda por mail a
las direcciones suscritas.

Al topic de entrada le llegan dos tipos de mensajes:
  1. Alarmas de CloudWatch (cuando una alarma cambia a ALARM u OK).
  2. Resultados del escaneo de ECR con vulnerabilidades HIGH o CRITICAL
     (EventBridge los reenvía al topic).

Sin la Lambda, el mail de un escaneo de ECR sería un JSON crudo. Con la
Lambda, todos los avisos llegan con el mismo formato: un asunto claro y
un texto con qué pasó, por qué y el link a la consola.

Solo usa la librería estándar de Python + boto3 (que ya viene en Lambda):
no hay dependencias que instalar ni empaquetar.
"""

import json
import os
import unicodedata

import boto3

MAIL_TOPIC_ARN = os.environ.get("MAIL_TOPIC_ARN", "")
REGION = os.environ.get("AWS_REGION", "us-east-1")

sns = boto3.client("sns")


# ---------------------------------------------------------------------------
# Formato de cada tipo de mensaje: devuelven (asunto, cuerpo)
# ---------------------------------------------------------------------------

def formatear_alarma(alarma):
    """Alarma de CloudWatch -> (asunto, cuerpo)."""
    estado = alarma.get("NewStateValue", "?")
    nombre = alarma.get("AlarmName", "(sin nombre)")
    url = (
        f"https://{REGION}.console.aws.amazon.com/cloudwatch/home"
        f"?region={REGION}#alarmsV2:alarm/{nombre}"
    )
    asunto = f"[{estado}] {nombre}"
    lineas = [
        f"La alarma {nombre} pasó a estado {estado}.",
        "",
        alarma.get("AlarmDescription") or "",
        f"Motivo: {alarma.get('NewStateReason', '')}",
        f"Hora (UTC): {alarma.get('StateChangeTime', '')}",
        "",
        f"Ver alarma: {url}",
    ]
    return asunto, "\n".join(lineas)


def formatear_escaneo_ecr(evento):
    """Resultado del escaneo de una imagen en ECR -> (asunto, cuerpo)."""
    detalle = evento.get("detail", {})
    repo = detalle.get("repository-name", "?")
    tags = ", ".join(detalle.get("image-tags") or []) or "(sin tag)"
    conteo = detalle.get("finding-severity-counts", {})
    resumen = ", ".join(
        f"{sev}: {conteo[sev]}"
        for sev in ("CRITICAL", "HIGH", "MEDIUM", "LOW")
        if conteo.get(sev)
    )
    url = (
        f"https://{REGION}.console.aws.amazon.com/ecr/repositories/private/"
        f"{evento.get('account', '')}/{repo}?region={REGION}"
    )
    asunto = f"[ECR] Vulnerabilidades en {repo}:{tags}"
    cuerpo = "\n".join([
        f"ECR escaneó la imagen {repo}:{tags} y encontró vulnerabilidades.",
        "",
        f"Hallazgos: {resumen or 'sin detalle'}",
        "Revisar si la imagen puede promoverse a test/prod.",
        "",
        f"Ver en ECR: {url}",
    ])
    return asunto, cuerpo


def formatear(mensaje_sns):
    """Decide el formato según qué hay dentro del mensaje de SNS."""
    mensaje = mensaje_sns.get("Message", "")
    try:
        datos = json.loads(mensaje)
    except (TypeError, ValueError):
        datos = None

    if isinstance(datos, dict) and "AlarmName" in datos:
        return formatear_alarma(datos)
    if isinstance(datos, dict) and datos.get("detail-type") == "ECR Image Scan":
        return formatear_escaneo_ecr(datos)

    # Cualquier otro mensaje: se manda tal cual
    return mensaje_sns.get("Subject") or "Notificación", mensaje


def asunto_valido(asunto):
    """SNS exige asunto ASCII, sin saltos de línea y de menos de 100 caracteres."""
    # "á" -> "a", "ñ" -> "n"; lo que no tiene equivalente (emojis) se descarta
    limpio = unicodedata.normalize("NFKD", asunto)
    limpio = limpio.encode("ascii", "ignore").decode("ascii")
    limpio = " ".join(limpio.split())
    return ("Tero: " + limpio)[:99].strip()


# ---------------------------------------------------------------------------
# Punto de entrada
# ---------------------------------------------------------------------------

def handler(event, context):
    enviados = 0
    for record in event.get("Records", []):
        asunto, cuerpo = formatear(record.get("Sns", {}))
        # Siempre queda en los logs: sirve de evidencia y para depurar
        print(f"{asunto}\n{cuerpo}")

        # Si falla, la excepción hace que Lambda reintente (SNS -> Lambda es
        # asíncrono: hasta 2 reintentos) y queda registrada en los logs.
        respuesta = sns.publish(
            TopicArn=MAIL_TOPIC_ARN,
            Subject=asunto_valido(asunto),
            Message=cuerpo,
        )
        print(f"Publicado en el topic de mail: {respuesta['MessageId']}")
        enviados += 1

    return {"enviados": enviados}
