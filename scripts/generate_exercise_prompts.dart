import 'dart:convert';
import 'dart:io';

/// Simple CSV reader that supports quoted fields.
/// Expects a header row with columns:
/// Name,Exercise type,BodyPart,Equipment,Gender,Target
List<Map<String, String>> readCsv(File file) {
  final lines = file.readAsLinesSync();
  if (lines.isEmpty) return [];

  final headers = _parseCsvLine(lines.first);
  final rows = <Map<String, String>>[];
  for (var i = 1; i < lines.length; i++) {
    final values = _parseCsvLine(lines[i]);
    if (values.isEmpty) continue;
    final map = <String, String>{};
    for (var j = 0; j < headers.length && j < values.length; j++) {
      map[headers[j]] = values[j];
    }
    rows.add(map);
  }
  return rows;
}

/// Parses a single CSV line handling commas inside double quotes.
List<String> _parseCsvLine(String line) {
  final result = <String>[];
  final buffer = StringBuffer();
  bool inQuotes = false;
  for (int i = 0; i < line.length; i++) {
    final char = line[i];
    if (char == '"') {
      // If we see a double quote, toggle inQuotes unless it's an escaped quote
      if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
        // Escaped quote within quoted field
        buffer.write('"');
        i++; // skip the next quote
      } else {
        inQuotes = !inQuotes;
      }
    } else if (char == ',' && !inQuotes) {
      result.add(buffer.toString().trim());
      buffer.clear();
    } else {
      buffer.write(char);
    }
  }
  result.add(buffer.toString().trim());
  // Remove surrounding quotes
  for (int i = 0; i < result.length; i++) {
    final v = result[i];
    if (v.startsWith('"') && v.endsWith('"') && v.length >= 2) {
      result[i] = v.substring(1, v.length - 1);
    }
  }
  return result;
}

String buildLlmPrompt({
  required String name,
  required String type,
  required String bodyPart,
  required String equipment,
  required String gender,
  required String target,
}) {
  final targetOrBody = target.isEmpty ? bodyPart : target;
  return """
You are a certified strength and conditioning coach. Generate clear, safe, and concise exercise instructions.

Input
- name: $name
- type: $type
- body_part: $bodyPart
- equipment: $equipment
- gender: $gender
- target: ${target.isEmpty ? '(empty)' : target}

Output JSON only (no prose) with:
{
  "name": "$name",
  "summary": "1–2 sentence overview for a "+"${gender.toLowerCase()}"+" using "+"${equipment.toLowerCase()}"+" targeting $targetOrBody.",
  "setup": ["...","..."],
  "execution": ["...","...","..."],
  "cues": ["...","..."],
  "breathing": "…",
  "common_mistakes": ["...","..."],
  "regressions": ["...","..."],
  "progressions": ["...","..."],
  "safety": ["...","..."],
  "equipment": "$equipment",
  "primary_muscles": ["${target.isEmpty ? bodyPart : target}"],
  "secondary_muscles": ["..."],
  "tempo": "e.g., 2-0-2",
  "range_of_motion": "short|moderate|full (describe endpoints)",
  "plane_of_motion": "sagittal|frontal|transverse",
  "unilateral": false,
  "difficulty": "beginner|intermediate|advanced",
  "sets_reps": "e.g., 3x8–12",
  "notes": "brief coaching notes"
}

Rules
- Use $gender-appropriate wording only where relevant (do not assume differences otherwise).
- Match instructions to $equipment (no extra gear).
- If target is empty, infer typical primary muscles for $bodyPart and the exercise name.
- Keep each list to 3–5 bullets. Keep it practical and safe.
- Do not include any text outside the JSON.
""".trim();
}

String buildImagePrompt({
  required String name,
  required String type,
  required String bodyPart,
  required String equipment,
  required String gender,
  required String target,
}) {
  final targetOrBody = target.isEmpty ? bodyPart : target;
  return "Instructional fitness photo of a ${gender.toLowerCase()} performing \"$name\", ${type.toLowerCase()}, targeting ${targetOrBody.toLowerCase()}, using ${equipment.toLowerCase()}. Neutral studio, 3/4 side view, mid-rep key position, clear joint angles, high-contrast lighting, no background clutter, athletic attire.";
}

void main(List<String> args) {
  // Parse args
  String inputPath = 'data/exercises_sample.csv';
  String outDir = 'prompts';
  for (int i = 0; i < args.length; i++) {
    if (args[i] == '--in' && i + 1 < args.length) inputPath = args[++i];
    if (args[i] == '--out' && i + 1 < args.length) outDir = args[++i];
  }

  final inputFile = File(inputPath);
  if (!inputFile.existsSync()) {
    stderr.writeln('Input file not found: $inputPath');
    exit(1);
  }

  final rows = readCsv(inputFile);
  if (rows.isEmpty) {
    stderr.writeln('No rows found in $inputPath');
    exit(1);
  }

  Directory(outDir).createSync(recursive: true);

  final llmOut = File('$outDir/llm_prompts.jsonl').openWrite();
  final imgOut = File('$outDir/image_prompts.jsonl').openWrite();

  for (final row in rows) {
    final name = row['Name']?.trim() ?? '';
    final type = row['Exercise type']?.trim() ?? '';
    final bodyPart = row['BodyPart']?.trim() ?? '';
    final equipment = row['Equipment']?.trim() ?? '';
    final gender = row['Gender']?.trim() ?? '';
    final target = row['Target']?.trim() ?? '';

    if (name.isEmpty) continue;

    final llmPrompt = buildLlmPrompt(
      name: name,
      type: type,
      bodyPart: bodyPart,
      equipment: equipment,
      gender: gender,
      target: target,
    );

    final imagePrompt = buildImagePrompt(
      name: name,
      type: type,
      bodyPart: bodyPart,
      equipment: equipment,
      gender: gender,
      target: target,
    );

    final llmObj = jsonEncode({
      'name': name,
      'exercise_type': type,
      'body_part': bodyPart,
      'equipment': equipment,
      'gender': gender,
      'target': target,
      'prompt': llmPrompt,
    });

    final imgObj = jsonEncode({
      'name': name,
      'prompt': imagePrompt,
    });

    llmOut.writeln(llmObj);
    imgOut.writeln(imgObj);
  }

  llmOut.close();
  imgOut.close();

  stdout.writeln('Wrote prompts to $outDir');
}

