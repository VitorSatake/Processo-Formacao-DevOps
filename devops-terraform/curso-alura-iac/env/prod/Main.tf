module "prod" {
  source = "../../../infra"

  nome_repo = "producao"
  cargoIAM = "producao"
}