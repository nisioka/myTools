import type { Questions, SystemOneResult } from "@typesafe-ai/sdk";

/** 0〜1 の確率を百分率の文字列にする。 */
const pct = (value: number): string => `${(value * 100).toFixed(1)}%`;

/** 確率を 20 桁のバーで表す。 */
const bar = (value: number): string => {
  const filled = Math.round(Math.min(Math.max(value, 0), 1) * 20);
  return `${"█".repeat(filled)}${"░".repeat(20 - filled)}`;
};

const describe = (entry: unknown): string => {
  if (entry === null || entry === undefined) return "";
  if (typeof entry === "string") return entry;
  return JSON.stringify(entry);
};

/** 確率の一覧を「ラベル バー 確率」の形で並べる。 */
const probabilityLines = (
  probabilities: Record<string, number>,
  labelOf: (key: string) => string,
): string[] => {
  const width = Math.max(...Object.keys(probabilities).map((key) => labelOf(key).length));
  return Object.entries(probabilities)
    .sort(([, a], [, b]) => b - a)
    .map(([key, value]) => `      ${labelOf(key).padEnd(width)}  ${bar(value)} ${pct(value)}`);
};

/** systemOne の応答を人間が読める形で標準出力に出す。 */
export const printResult = <Q extends Questions>(result: SystemOneResult<Q>): void => {
  for (const [name, answer] of Object.entries(result.answers)) {
    switch (answer.type) {
      case "noul": {
        console.log(`\n  ${name} (noul)`);
        console.log(`      yes の確率  ${bar(answer.noul)} ${pct(answer.noul)}`);
        break;
      }
      case "choice": {
        console.log(`\n  ${name} (choice) => ${answer.choice}  [confidence ${pct(answer.confidence)}]`);
        console.log(probabilityLines(answer.probabilities as Record<string, number>, (key) => key).join("\n"));
        break;
      }
      case "score": {
        const legend = answer.legend as Record<string, unknown>;
        const levels = Object.keys(legend).length - 1;
        console.log(
          `\n  ${name} (score) => ${answer.score.toFixed(2)} / ${levels}  [confidence ${pct(answer.confidence)}]`,
        );
        console.log(
          probabilityLines(
            answer.probabilities as Record<string, number>,
            (key) => `${key}: ${describe(legend[key])}`,
          ).join("\n"),
        );
        break;
      }
    }
  }
  console.log(
    `\n  --- model: ${result.model} / input ${result.usage.input_tokens} tok, output ${result.usage.output_tokens} tok ---`,
  );
};
