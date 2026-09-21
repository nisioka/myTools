import { choice, noul, score } from "@typesafe-ai/sdk";
import { createClient, die } from "./client.ts";
import { printResult } from "./format.ts";

const SAMPLE_STATE =
  "先日納車された車のナビが3日連続でフリーズします。仕事で毎日使うので早く見てほしいのですが、" +
  "平日は店舗に行けません。代車を出してもらえるなら土曜に入庫できます。";

/**
 * 問い合わせ文を 1 回の呼び出しで仕分けるデモ。
 * noul / choice / score の 3 プリミティブを同時に投げている。
 */
const main = async (): Promise<void> => {
  const state = process.argv.slice(2).join(" ") || SAMPLE_STATE;
  const client = createClient();

  console.log(`state:\n  ${state}`);

  const result = await client.systemOne({
    state,
    questions: {
      is_urgent: noul("この問い合わせは時間的な緊急性を含んでいる"),
      department: choice("どの部署が対応すべきか", {
        service: "整備・修理・不具合の対応",
        sales: "見積り・購入・契約に関する相談",
        parts: "部品やアクセサリの手配",
      }),
      frustration: score("顧客の不満の強さ", [
        "落ち着いて事実を述べている",
        "苛立っているが丁寧",
        "強い言葉で怒っている",
      ]),
      needs_loaner: noul("代車の手配が必要になりそうだ"),
    },
  });

  printResult(result);
};

main().catch(die);
