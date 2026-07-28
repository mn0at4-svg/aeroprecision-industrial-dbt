import base64
import hashlib
import json
import os
import time
import uuid
import urllib.error
import urllib.request
from pathlib import Path

BASE_URL = "http://127.0.0.1:3000"
SECRET_FILE = (
    Path(os.environ["USERPROFILE"])
    / ".aeroprecision-secrets"
    / "langfuse.env"
)


def load_secret_file(path):
    if not path.is_file():
        raise RuntimeError("Langfuse secret file was not found outside Git.")

    values = {}

    for original_line in path.read_text(encoding="utf-8-sig").splitlines():
        line = original_line.strip()

        if not line or line.startswith("#"):
            continue

        if "=" not in line:
            raise RuntimeError("Invalid secret-file line format.")

        name, value = line.split("=", 1)
        value = value.strip()

        if (
            len(value) >= 2
            and value[0] == value[-1]
            and value[0] in ("'", '"')
        ):
            value = value[1:-1]

        values[name.strip()] = value

    public_key = values.get("LANGFUSE_PUBLIC_KEY", "")
    secret_key = values.get("LANGFUSE_SECRET_KEY", "")

    if not public_key.startswith("pk-lf-"):
        raise RuntimeError("Invalid Langfuse public-key format.")

    if not secret_key.startswith("sk-lf-"):
        raise RuntimeError("Invalid Langfuse secret-key format.")

    return public_key, secret_key


def hash_hex(value):
    return hashlib.sha256(value.encode("utf-8")).hexdigest()


def span_id(seed):
    candidate = hash_hex(seed)[:16]

    if candidate == "0" * 16:
        raise RuntimeError("Generated an invalid zero span ID.")

    return candidate


def attribute(key, value):
    if isinstance(value, bool):
        otel_value = {"boolValue": value}
    elif isinstance(value, int):
        otel_value = {"intValue": str(value)}
    elif isinstance(value, float):
        otel_value = {"doubleValue": value}
    elif isinstance(value, list):
        otel_value = {
            "arrayValue": {
                "values": [{"stringValue": str(item)} for item in value]
            }
        }
    else:
        otel_value = {"stringValue": str(value)}

    return {"key": key, "value": otel_value}


public_key, secret_key = load_secret_file(SECRET_FILE)

canary_id = uuid.uuid4().hex[:12]
rfq_id = f"SYNTH-P3-CANARY-{canary_id}"
business_trace_id = f"{rfq_id}:phase2-calc-v1"
trace_id = hash_hex(business_trace_id)[:32]

if trace_id == "0" * 32:
    raise RuntimeError("Generated an invalid zero trace ID.")

root_span_id = span_id(business_trace_id + ":root")
generation_span_id = span_id(business_trace_id + ":generation")
validation_span_id = span_id(business_trace_id + ":validation")

input_hash = hash_hex("phase3-l0-canary-input")
output_hash = hash_hex("phase3-l0-canary-output")

start_ns = time.time_ns()
generation_start_ns = start_ns + 100_000_000
generation_end_ns = start_ns + 300_000_000
validation_start_ns = start_ns + 350_000_000
validation_end_ns = start_ns + 450_000_000
root_end_ns = start_ns + 500_000_000

trace_metadata = {
    "business_trace_id": business_trace_id,
    "rfq_id": rfq_id,
    "workflow_execution_id": "phase3-canary",
    "calculation_version": "phase2-calc-v1",
    "prompt_version": "phase2-ollama-explanation-v1",
    "data_classification": "L0",
    "request_channel": "synthetic-canary",
}

common_attributes = [
    attribute("langfuse.trace.name", "rfq-quotation"),
    attribute(
        "langfuse.trace.tags",
        ["phase3-canary", "synthetic", "l0-only"],
    ),
    attribute(
        "langfuse.trace.metadata",
        json.dumps(trace_metadata, separators=(",", ":")),
    ),
    attribute("langfuse.environment", "development"),
    attribute("langfuse.version", "phase3-otel-canary-v1"),
]

root_attributes = common_attributes + [
    attribute("langfuse.observation.type", "span"),
    attribute(
        "langfuse.observation.input",
        json.dumps(
            {"sha256": input_hash, "data_classification": "L0"},
            separators=(",", ":"),
        ),
    ),
    attribute(
        "langfuse.observation.output",
        json.dumps(
            {"sha256": output_hash, "status": "canary_complete"},
            separators=(",", ":"),
        ),
    ),
    attribute(
        "langfuse.observation.metadata",
        json.dumps(
            {
                "workflow_execution_id": "phase3-canary",
                "calculation_version": "phase2-calc-v1",
            },
            separators=(",", ":"),
        ),
    ),
]

generation_attributes = common_attributes + [
    attribute("langfuse.observation.type", "generation"),
    attribute("langfuse.observation.model.name", "qwen3:8b"),
    attribute(
        "langfuse.observation.input",
        json.dumps(
            {"sha256": input_hash, "length": 24},
            separators=(",", ":"),
        ),
    ),
    attribute(
        "langfuse.observation.output",
        json.dumps(
            {"sha256": output_hash, "length": 25},
            separators=(",", ":"),
        ),
    ),
    attribute(
        "langfuse.observation.usage_details",
        json.dumps(
            {"input": 12, "output": 7, "total": 19},
            separators=(",", ":"),
        ),
    ),
    attribute(
        "langfuse.observation.cost_details",
        json.dumps(
            {"input": 0, "output": 0, "total": 0},
            separators=(",", ":"),
        ),
    ),
    attribute(
        "langfuse.observation.metadata",
        json.dumps(
            {
                "provider": "ollama",
                "attempt": 1,
                "max_attempts": 3,
                "prompt_version": "phase2-ollama-explanation-v1",
                "latency_ms": 200,
                "validation_status": "pass",
                "validation_errors": [],
                "retry_decision": "stop",
                "loop_stop_reason": "valid_output",
                "data_classification": "L0",
            },
            separators=(",", ":"),
        ),
    ),
]

validation_attributes = common_attributes + [
    attribute("langfuse.observation.type", "span"),
    attribute(
        "langfuse.observation.metadata",
        json.dumps(
            {
                "validation_status": "pass",
                "validation_errors": [],
                "retry_decision": "stop",
                "loop_stop_reason": "valid_output",
            },
            separators=(",", ":"),
        ),
    ),
]

payload = {
    "resourceSpans": [
        {
            "resource": {
                "attributes": [
                    attribute(
                        "service.name",
                        "aeroprecision-n8n-phase3-canary",
                    )
                ]
            },
            "scopeSpans": [
                {
                    "scope": {
                        "name": "aeroprecision.phase3.canary",
                        "version": "1.0.0",
                    },
                    "spans": [
                        {
                            "traceId": trace_id,
                            "spanId": root_span_id,
                            "name": "rfq-quotation",
                            "kind": 1,
                            "startTimeUnixNano": str(start_ns),
                            "endTimeUnixNano": str(root_end_ns),
                            "attributes": root_attributes,
                            "status": {"code": 1},
                        },
                        {
                            "traceId": trace_id,
                            "spanId": generation_span_id,
                            "parentSpanId": root_span_id,
                            "name": "ollama-quote-explanation",
                            "kind": 1,
                            "startTimeUnixNano": str(generation_start_ns),
                            "endTimeUnixNano": str(generation_end_ns),
                            "attributes": generation_attributes,
                            "status": {"code": 1},
                        },
                        {
                            "traceId": trace_id,
                            "spanId": validation_span_id,
                            "parentSpanId": root_span_id,
                            "name": "ai-output-validation",
                            "kind": 1,
                            "startTimeUnixNano": str(validation_start_ns),
                            "endTimeUnixNano": str(validation_end_ns),
                            "attributes": validation_attributes,
                            "status": {"code": 1},
                        },
                    ],
                }
            ],
        }
    ]
}

authentication = base64.b64encode(
    f"{public_key}:{secret_key}".encode("utf-8")
).decode("ascii")

request = urllib.request.Request(
    BASE_URL + "/api/public/otel/v1/traces",
    data=json.dumps(payload, separators=(",", ":")).encode("utf-8"),
    headers={
        "Authorization": "Basic " + authentication,
        "Content-Type": "application/json",
    },
    method="POST",
)

try:
    with urllib.request.urlopen(request, timeout=10) as response:
        ingestion_status = response.status
except urllib.error.HTTPError as error:
    error_body = error.read().decode("utf-8", errors="replace")[:1000]
    raise RuntimeError(
        f"OTLP ingestion failed: HTTP {error.code}; body={error_body}"
    ) from error

if ingestion_status not in (200, 202):
    raise RuntimeError(f"Unexpected ingestion status: {ingestion_status}")

trace_response = None

for _ in range(15):
    trace_request = urllib.request.Request(
        BASE_URL + "/api/public/traces/" + trace_id,
        headers={"Authorization": "Basic " + authentication},
        method="GET",
    )

    try:
        with urllib.request.urlopen(trace_request, timeout=10) as response:
            candidate = json.loads(response.read().decode("utf-8"))

        if len(candidate.get("observations", [])) >= 3:
            trace_response = candidate
            break
    except urllib.error.HTTPError as error:
        if error.code != 404:
            error_body = error.read().decode(
                "utf-8",
                errors="replace",
            )[:1000]
            raise RuntimeError(
                f"Trace lookup failed: HTTP {error.code}; body={error_body}"
            ) from error

    time.sleep(2)

if trace_response is None:
    raise RuntimeError(
        "Canary was accepted, but three observations were not readable "
        "within 30 seconds."
    )

observation_names = sorted(
    observation.get("name", "")
    for observation in trace_response.get("observations", [])
)

required_names = sorted(
    [
        "rfq-quotation",
        "ollama-quote-explanation",
        "ai-output-validation",
    ]
)

if observation_names != required_names:
    raise RuntimeError(
        "Unexpected observations: " + ",".join(observation_names)
    )

serialized_response = json.dumps(trace_response, ensure_ascii=False)

for forbidden_value in (
    "phase3-l0-canary-input",
    "phase3-l0-canary-output",
    public_key,
    secret_key,
):
    if forbidden_value in serialized_response:
        raise RuntimeError(
            "Forbidden raw or secret value was returned by Langfuse."
        )

print("PASS: OTLP canary ingestion")
print(f"CanaryTraceId={trace_id}")
print(f"BusinessTraceId={business_trace_id}")
print(f"ObservationCount={len(observation_names)}")
print("ObservationNames=" + ",".join(observation_names))
print("RawPromptStored=False")
print("RawOutputStored=False")
print("DataClassification=L0")
