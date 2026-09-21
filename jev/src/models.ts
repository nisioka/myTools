import { createClient, die } from "./client.ts";

/** アカウントで使えるモデルの一覧を出す。 */
const main = async (): Promise<void> => {
  const models = await createClient().models.list();
  for (const model of models) {
    console.log(`${model.name}\t${model.release_date}\t${model.description}`);
  }
};

main().catch(die);
