#!/usr/bin/env python3

import os
import requests
from langfuse import Langfuse
from dotenv import load_dotenv

load_dotenv()

LANGFUSE_HOST = os.environ["LANGFUSE_BASE_URL"].rstrip("/")
LANGFUSE_PUBLIC_KEY = os.environ["LANGFUSE_PUBLIC_KEY"]
LANGFUSE_SECRET_KEY = os.environ["LANGFUSE_SECRET_KEY"]

langfuse = Langfuse(
    public_key=LANGFUSE_PUBLIC_KEY,
    secret_key=LANGFUSE_SECRET_KEY,
    host=LANGFUSE_HOST,
)


def get_sessions(limit: int = 50) -> list[dict]:
    response = requests.get(
        f"{LANGFUSE_HOST}/api/public/sessions",
        auth=(LANGFUSE_PUBLIC_KEY, LANGFUSE_SECRET_KEY),
        params={"limit": limit},
        timeout=30,
    )
    response.raise_for_status()
    data = response.json()
    return data.get("data", data if isinstance(data, list) else [])


def score_session(session: dict) -> dict[str, tuple[float, str]]:
    total_tokens = int(session.get("totalTokens") or 0)
    trace_count = int(session.get("countTraces") or 0)

    coverage = min(100, round(trace_count / 10 * 100, 2))
    usage_quality = min(100, round(total_tokens / 20_000 * 100, 2))

    return {
        "openwebui_trace_coverage": (
            coverage,
            f"{trace_count} traces observed in this Open WebUI session.",
        ),
        "openwebui_token_depth": (
            usage_quality,
            f"{total_tokens} tokens observed in this Open WebUI session.",
        ),
    }


def push_score(session_id: str, name: str, value: float, comment: str) -> None:
    # Note: if your SDK version has a session_id bug, upgrade langfuse first.
    langfuse.create_score(
        name=name,
        value=value,
        data_type="NUMERIC",
        session_id=session_id,
        comment=comment,
    )


def main() -> None:
    sessions = get_sessions(limit=100)

    for session in sessions:
        session_id = session.get("id")
        if not session_id:
            continue

        scores = score_session(session)

        for name, (value, comment) in scores.items():
            print(f"Scoring session={session_id} {name}={value}")
            push_score(session_id, name, value, comment)

    langfuse.flush()


if __name__ == "__main__":
    main()
