import { TypeSafeClient } from "@typesafe-ai/sdk";

/**
 * 環境変数 TYPESAFE_API_KEY からクライアントを作る。
 * キーが無いときは SDK の例外の代わりに手順を出して終了する。
 */
export const createClient = (): TypeSafeClient => {
  if (!process.env.TYPESAFE_API_KEY?.trim()) {
    console.error(
      [
        "TYPESAFE_API_KEY が設定されていません。",
        "",
        "  cp .env.example .env    # そのうえで .env にキーを書く",
        "  もしくは  export TYPESAFE_API_KEY=ts_...",
        "",
        "キーの発行: https://console.typesafe.ai/keys",
      ].join("\n"),
    );
    process.exit(1);
  }
  return new TypeSafeClient();
};

/** 例外を CLI 向けのメッセージにして終了する。 */
export const die = (error: unknown): never => {
  console.error(`\n[error] ${error instanceof Error ? error.message : String(error)}`);
  process.exit(1);
};
