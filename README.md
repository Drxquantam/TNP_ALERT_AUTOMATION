# Email Processing & Alert Automation (n8n Workflow)

## Overview

This n8n workflow automatically reads incoming Gmail messages, verifies the sender, runs the email content through an AI Agent (Google Gemini + Postgres-backed chat memory) for classification/structured extraction, cross-references a Google Sheet, and then either logs the result, raises an alert, or halts with an error — depending on how each validation step resolves.It also adds the data to the Google sheets, removing manual entry and saving a lot of time and improving productivity.

![Workflow diagram](images/image1.png)

## Flow Summary

1. **Gmail Trigger** — fires when a new email arrives.
2. **Get a thread** (`get: thread`) — fetches the full email thread.
3. **Split Out** — splits the thread into individual items.
4. **Get a message** (`get: message`) — retrieves message details for each item.
5. **Aggregate** — merges the split items back into a single collection.
6. **Checking_mail_sender** (IF node) — validates the sender:
   - **true** → continues to the AI Agent
   - **false** → **Stop and Error** (invalid/unrecognized sender halts the run)
7. **AI Agent** — processes the email content, using:
   - **Google Gemini Chat Model** as the LLM
   - **Postgres Chat Memory** for conversation/context memory
   - **Structured Output Parser** to enforce a defined output schema
8. **If1** (IF node) — validates the AI Agent's output:
   - **true** → **Get row(s) in sheet** (`read: sheet`) — looks up matching data in Google Sheets
   - **false** → **Stop and Error2** (AI output failed validation)
9. **Merge** (`chooseBranch`) — combines the AI Agent path and the sheet-read path into one stream.
10. **If** (IF node) — final check on the merged data:
    - **true** → **Stop and Error1** (final validation failure)
    - **false** → **Update_Data** (`append: sheet`) — appends the processed result to the Google Sheet, and **Send an Alert** (`send: message`, Discord) — notifies a Discord channel.

## Nodes at a Glance

| Node | Type | Purpose |
|---|---|---|
| Gmail Trigger | Trigger | Starts workflow on new email |
| Get a thread | Gmail | Fetch email thread |
| Split Out | Split Out | Split thread into items |
| Get a message | Gmail | Fetch message details |
| Aggregate | Aggregate | Recombine items |
| Checking_mail_sender | IF | Validate sender |
| AI Agent | LangChain Agent | Classify/extract email content |
| Google Gemini Chat Model | LLM | Model backing the AI Agent |
| Postgres Chat Memory | Memory | Conversation memory store |
| Structured Output Parser | Output Parser | Enforces structured AI output |
| If1 | IF | Validate AI Agent output |
| Get row(s) in sheet | Google Sheets | Read matching rows |
| Merge | Merge | Combine parallel branches |
| If | IF | Final validation gate |
| Update_Data | Google Sheets | Append processed result |
| Send an Alert | Discord | Send notification |
| Stop and Error / Stop and Error1 / Stop and Error2 | Stop and Error | Halt execution on validation failure |

## Error Handling

The workflow has three dedicated failure points:
- **Stop and Error** — triggered when the sender check fails.
- **Stop and Error2** — triggered when the AI Agent's output doesn't pass `If1`'s validation.
- **Stop and Error1** — triggered when the final merged-data check (`If`) fails.

## Notes

- The exact routing into the **Merge** node's two inputs and the final **If → Send an Alert** path was read directly off the diagram; double-check these connections in the actual n8n canvas before relying on this document, since a few crossing lines were hard to disambiguate visually.
- Update this README if node names, credentials, or branch logic change.
