module "code-server" {
  count                   = data.coder_workspace.me.start_count
  source                  = "registry.coder.com/coder/code-server/coder"
  version                 = "1.5.0"
  agent_id                = coder_agent.main.id
  additional_args         = ""
  auto_install_extensions = false
  extensions_dir          = ""
  folder                  = "/home/coder/projects"
  install_version         = ""
  offline                 = false
  open_in                 = "slim-window"
  port                    = 13337
  use_cached              = false
  use_cached_extensions   = false
  workspace               = ""
}
