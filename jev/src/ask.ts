import { readFile } from "node:fs/promises";
import type { EntryType, Questions } from "@typesafe-ai/sdk";
import { createClient, die } from "./client.ts";
import { printResult } from "./format.ts";

const USAGE = `使い方:
  pnpm ask <questions.json> [state...]
  cat state.txt | pnpm ask <questions.json>

  questions.json は API のリクエストの questions と同じ形:
    { "urgency": { "type": "noul", "instructions": "..." } }
  state が { か [ で始まるときは JSON として送る（構造化 state）。`;

/** 引数、なければ標準入力から state を読む。 */
const readState = async (fromArgs: string): Promise<string> => {
  if (fromArgs) return fromArgs;
  if (process.stdin.isTTY) {
    console.error(USAGE);
    process.exit(1);
  }
  const chunks: Buffer[] = [];
  for await (const chunk of process.stdin) chunks.push(chunk as Buffer);
  return Buffer.concat(chunks).toString("utf8").trim();
};

/** JSON らしき文字列なら構造化 state として解釈する。 */
const parseState = (raw: string): EntryType => {
  if (!/^[[{]/.test(raw)) return raw;
  try {
    return JSON.parse(raw) as EntryType;
  } catch {
    return raw;
  }
};

const main = async (): Promise<void> => {
  const [questionsPath, ...rest] = process.argv.slice(2);
  if (!questionsPath) {
    console.error(USAGE);
    process.exit(1);
  }

  const questions = JSON.parse(await readFile(questionsPath, "utf8")) as Questions;
  const state = parseState(await readState(rest.join(" ")));
  if (!state) die(new Error("state が空です。"));

  const result = await createClient().systemOne({ state, questions });
  printResult(result);
};

main().catch(die);
