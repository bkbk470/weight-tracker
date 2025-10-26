This folder will contain generated prompts.

How to generate (sample):

1) Ensure you have Dart installed (Flutter repo should already have it).
2) From the repo root, run:

   dart scripts/generate_exercise_prompts.dart --in data/exercises_sample.csv --out prompts

3) Outputs:
   - prompts/llm_prompts.jsonl        (one JSON object per line with a fully formed LLM prompt)
   - prompts/image_prompts.jsonl      (one JSON object per line with a concise image prompt)

To use with your full dataset, prepare a CSV with headers:

Name,Exercise type,BodyPart,Equipment,Gender,Target

Then point --in to that file. Fields containing commas must be quoted.

Each LLM prompt follows the schema and rules discussed (JSON-only response, coaching details, safety, progressions, etc.).

