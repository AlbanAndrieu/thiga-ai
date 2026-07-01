#!/usr/bin/env bash
set -Eeuo pipefail
WORKING_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")"&&  pwd)"
source "$WORKING_DIR/step-0-color.sh"
OPEN_WEBUI_URL="${OPEN_WEBUI_URL:-http://localhost:31028}"
OPEN_WEBUI_EMAIL="${OPEN_WEBUI_EMAIL:?Missing OPEN_WEBUI_EMAIL}"
OPEN_WEBUI_PASSWORD="${OPEN_WEBUI_PASSWORD:?Missing OPEN_WEBUI_PASSWORD}"
KB_NAME="CV and postion matcher For Thiga"
KB_DESCRIPTION="CV and postion matcher For Thiga."
MODEL_ID="assistant-thiga-solution-architect"
MODEL_NAME="Assistant Thiga Solution Architect"
BASE_MODEL="qwen"
CV_FILE="data/cv/Alban Andrieu - CV (Complet) - Français.pdf"
JOB_FILE="data/position/fiche_poste_solution_architect-thiga.pdf"
SYSTEM_PROMPT="
You are a senior Solution Architect recruitment assistant specialized in Cloud, DevSecOps, Cybersecurity, AI and Platform Engineering.

You have access to a Knowledge Base that contains ONLY the following documents:

- Alban Andrieu's complete CV (French)
- The Thiga Solution Architect job description (French)

These documents are your PRIMARY source of truth.

--------------------------------------------------
IMPORTANT RULES
--------------------------------------------------

Before answering ANY question:

1. Always search the Knowledge Base.
2. Read every relevant document.
3. Build your answer ONLY from the retrieved documents.
4. Use your own knowledge only to interpret or explain what is written in those documents.
5. Never invent experience, certifications or skills.
6. If information is missing from the documents, explicitly state that it is not present.
7. NEVER answer:
   - \"I don't have access to the CV\"
   - \"I cannot analyse resumes\"
   - \"I don't have CV analysis tools\"
   - \"I cannot compare job descriptions\"

The Knowledge Base already contains everything required.

--------------------------------------------------
YOUR ROLE
--------------------------------------------------

You are acting as:

- Senior Technical Recruiter
- Principal Solution Architect
- DevSecOps Expert
- Cloud Architect
- Engineering Manager

Your goal is to evaluate how well the candidate matches the position.

--------------------------------------------------
TASKS
--------------------------------------------------

You can:

- analyse the CV
- analyse the job description
- compare both
- identify strengths
- identify missing skills
- identify transferable skills
- identify business value
- estimate hiring risks
- rewrite CV sections
- improve cover letters
- prepare interviews
- generate STAR answers
- propose technical examples
- explain architecture choices

--------------------------------------------------
OUTPUT FORMAT
--------------------------------------------------

Always produce the following sections.

# Executive Summary

5–10 concise lines.

# Strong Matches

List every requirement fully covered.

# Partial Matches

List partially covered requirements and explain why.

# Missing Skills

Only list genuine missing skills.

# Transferable Experience

Explain why previous experience is relevant.

# Competitive Advantages

Explain what makes the candidate stronger than an average applicant.

# Hiring Risks

Explain what may concern a recruiter.

# CV Improvements

Suggest concrete improvements.

# Interview Preparation

Generate probable interview questions with ideal answers.

# Overall Assessment

Provide the following scores:

- Overall Match: XX/100
- Technical Skills: XX/100
- Solution Architecture: XX/100
- Cloud: XX/100
- DevSecOps: XX/100
- AI / GenAI: XX/100
- Security: XX/100
- Leadership: XX/100
- Communication: XX/100

Explain every score.

Finally provide:

Hiring Recommendation

🟢 Excellent Candidate (90–100)

🟢 Strong Candidate (80–89)

🟡 Good Candidate (70–79)

🟠 Candidate Needs Improvement (60–69)

🔴 Weak Match (<60)

Also estimate the probability of receiving an offer (0–100%) and justify it.

--------------------------------------------------
LANGUAGE
--------------------------------------------------

The documents are written in French.

Read them in French.

Unless the user explicitly requests another language, answer in French.

When quoting the documents, preserve the original French wording.

--------------------------------------------------
CITATIONS
--------------------------------------------------

Whenever possible, cite the retrieved document(s) that support your conclusions.
"
log()
       {
         echo -e "$green==>$NC $*"
}
warn()
       {
         echo -e "${yellow}WARN:$NC $*"
}
err()
       {
         echo -e "${red}ERROR:$NC $*"   >&2
}
require_file()
               {
  [[ -f $1   ]]||  {
    err "File not found: $1"
    exit 1
}
}
api()
      {
  curl -sS "$@" -H "Authorization: Bearer $OPEN_WEBUI_TOKEN"
}
require_file "$CV_FILE"
require_file "$JOB_FILE"
log "Get Open WebUI JWT"
OPEN_WEBUI_TOKEN="$(curl -sS -X POST "$OPEN_WEBUI_URL/api/v1/auths/signin" \
    -H "Content-Type: application/json" \
    -d "$(jq -n \
      --arg email "$OPEN_WEBUI_EMAIL" \
      --arg password "$OPEN_WEBUI_PASSWORD" \
      '{email:$email, password:$password}')"|jq -r '.token // empty')"
[[ -n $OPEN_WEBUI_TOKEN   ]]||  {
  err "Could not get Open WebUI token"
  exit 1
}
log "Authenticated"
delete_existing_model()
                        {
  log "Deleting existing assistant model if present: $MODEL_ID"
  local endpoints=(
    "/api/v1/models/model/$MODEL_ID/delete"
    "/api/v1/models/model/$MODEL_ID"
    "/api/models/$MODEL_ID")
  for endpoint in "${endpoints[@]}";do
    status="$(curl -sS -o /tmp/openwebui-delete-model.json -w "%{http_code}" \
        -X DELETE "$OPEN_WEBUI_URL$endpoint" \
        -H "Authorization: Bearer $OPEN_WEBUI_TOKEN"||    true)"
    if [[ $status == "200" || $status == "204"     ]];then
      log "Deleted model via $endpoint"
      return 0
fi
done
  warn "Could not delete existing model. It may still exist."
}
delete_existing_knowledge()
                            {
  log "Deleting existing knowledge bases named: $KB_NAME"
  mapfile -t ids < <(api "$OPEN_WEBUI_URL/api/v1/knowledge/"|jq -r --arg name "$KB_NAME" '.items[]? | select(.name == $name) | .id')
  for id in "${ids[@]}";do
    [[ -z $id   ]]&&  continue
    log "Deleting knowledge base: $id"
    status="$(curl -sS -o /tmp/openwebui-delete-kb.json -w "%{http_code}" \
        -X DELETE "$OPEN_WEBUI_URL/api/v1/knowledge/$id/delete" \
        -H "Authorization: Bearer $OPEN_WEBUI_TOKEN"||    true)"
    if [[ $status != "200" && $status != "204"     ]];then
      warn "Could not delete KB $id, HTTP $status"
      cat /tmp/openwebui-delete-kb.json||  true
fi
done
}
create_knowledge()
                   {
  log "Creating knowledge base"
  KB_ID="$(api -X POST "$OPEN_WEBUI_URL/api/v1/knowledge/create" \
      -H "Content-Type: application/json" \
      -d "$(jq -n \
        --arg name "$KB_NAME" \
        --arg description "$KB_DESCRIPTION" \
        '{name:$name, description:$description}')"|jq -r '.id // empty')"
  [[ -n $KB_ID   ]]||  {
    err "Knowledge base creation failed"
    exit 1
}
  log "Knowledge base id: $KB_ID"
}
KNOWLEDGE_FILES_JSON="[]"
upload_file()
              {
  local file="$1"
  log "Uploading: $file"
  local uploaded file_id file_json
  uploaded="$(api -X POST "$OPEN_WEBUI_URL/api/v1/files/" \
      -F "file=@$file")"
  file_id="$(echo "$uploaded"|  jq -r '.id // empty')"
  [[ -n $file_id   ]]||  {
                           err "Upload failed: $file"
                                                       echo "$uploaded"
                                                                         exit 1
}
  log "File id: $file_id"
  sleep 3
  log "Adding file to knowledge base"
  api -X POST "$OPEN_WEBUI_URL/api/v1/knowledge/$KB_ID/file/add" \
    -H "Content-Type: application/json" \
    -d "$(jq -n --arg file_id "$file_id" '{file_id:$file_id}')" > \
/dev/null
  file_json="$(api "$OPEN_WEBUI_URL/api/v1/files/$file_id")"
  collection_name="$(echo "$file_json"|  jq -r '.meta.collection_name // empty')"
  if [[ -z $collection_name   ]];then
    collection_name="$KB_ID"
fi
  if [[ -z $COLLECTION_NAME   ]];then
    COLLECTION_NAME="$collection_name"
fi
  file_json="$(echo "$file_json"|jq \
      --arg kb "$KB_ID" \
      --arg kb_name "$KB_NAME" \
      --arg collection_name "$collection_name" \
      '
      . + {
        type: "file",
        name: .filename,
        description: "",
        collection: {
          id: $kb,
          name: $kb_name
        }
      }
      | .meta.collection_name = $collection_name
      ')"
  KNOWLEDGE_FILES_JSON="$(jq -n \
      --argjson current "$KNOWLEDGE_FILES_JSON" \
      --argjson file "$file_json" \
      '$current + [$file]')"
}
create_assistant_model()
                         {
  log "Creating custom assistant model"
  payload="$(jq -n \
      --arg id "$MODEL_ID" \
      --arg name "$MODEL_NAME" \
      --arg base "$BASE_MODEL" \
      --arg prompt "$SYSTEM_PROMPT" \
      --argjson knowledge "$KNOWLEDGE_FILES_JSON" \
      --arg kb "$KB_ID" \
      '{
        id:$id,
        name:$name,
        base_model_id:$base,
        params:{
          system:$prompt
        },
        meta:{
          profile_image_url:"",
          description:"Assistant RAG pour comparer le CV avec la fiche de poste Thiga.",
          capabilities:{
            "file_context": true,
            "citations": true,
            "vision": false,
            "file_upload": false,
            "web_search": false,
            "image_generation": false,
            "code_interpreter": false,
            "terminal": false,
            "builtin_tools": false
	  },
	  knowledge:$knowledge
        }
      }')"
  response="$(api -X POST "$OPEN_WEBUI_URL/api/v1/models/create" \
      -H "Content-Type: application/json" \
      -d "$payload")"
  echo "$response"|  jq .
  if echo "$response"|  jq -e '(.detail // "") | test("already registered")' > /dev/null;then
    err "Model already exists and could not be deleted: $MODEL_ID"
    err "Find the correct endpoint with: curl \$OPEN_WEBUI_URL/openapi.json | jq '.paths | keys[]' | grep -i model"
    exit 1
fi
}
verify()
         {
  log "Verifying knowledge base"
  api "$OPEN_WEBUI_URL/api/v1/knowledge/"|jq --arg id "$KB_ID" '.items[]? | select(.id == $id)'
  log "If the assistant still does not use RAG, inspect the model manually in:"
  echo "Workspace → Models → $MODEL_NAME → Knowledge"
}
delete_existing_model
delete_existing_knowledge
create_knowledge
COLLECTION_NAME=""
upload_file "$CV_FILE"
upload_file "$JOB_FILE"
log "Knowledge files attached to assistant"
echo "$KNOWLEDGE_FILES_JSON"|  jq .
log "Knowledge files JSON used for assistant"
echo "$KNOWLEDGE_FILES_JSON"|  jq '.[].meta.collection_name'
create_assistant_model
verify
log "Done"
