module Mrbmacs
  # install LSP servers
  class Application
    def lsp_find_server(lang)
      # return false if @ext.data['lsp'][lang].nil?
      return false if @ext.config['lsp'][lang].nil?
      return true if File.exist?(@ext.config['lsp'][lang]['command'])
      return true unless Which.which(@ext.config['lsp'][lang]['command']).nil?

      false
    end

    def lsp_installed_servers
      installed_servers = {}
      LSP_SERVERS.each do |k, v|
        v.each do |s|
          if !lsp_server_dir(s['command']).nil? && Dir.exist?(lsp_server_dir(s['command']))
            installed_servers[k] = { 'command' => "#{lsp_server_dir(s['command'])}/#{s['command']}",
                                     'options' => s['options'] }
            break
          end
        end
      end
      installed_servers
    end

    def lsp_data_dir(create_dir = false)
      data_dir = if !ENV['LOCALAPPDATA'].nil?
                   "#{ENV['LOCALAPPDATA']}/mrbmacs-lsp/"
                 elsif !ENV['XDG_DATA_HOME'].nil?
                   "#{ENV['XDG_DATA_HOME']}/mrbmacs-lsp/"
                 elsif !ENV['HOME'].nil?
                   "#{ENV['HOME']}/.local/share/mrbmacs-lsp/"
                 end
      if create_dir && !Dir.exist?(data_dir)
        Dir.mkdir(data_dir)
      end
      if Dir.exist?(data_dir)
        data_dir
      else
        nil
      end
    end

    def lsp_server_dir(server, create_dir = false)
      data_dir = lsp_data_dir
      return nil if data_dir.nil?

      if create_dir && !Dir.exist?("#{data_dir}/servers")
        Dir.mkdir("#{data_dir}/servers")
      end
      if Dir.exist?("#{data_dir}/servers")
        "#{data_dir}servers/#{server}"
      else
        nil
      end
    end

    def lsp_installer_dir
      # check vim-lsp-settings/installer
      homedir = Mrbmacs.homedir
      return if homedir == ''

      installer_dir = "#{homedir}/.vim/plugged/vim-lsp-settings/installer"
      return installer_dir if Dir.exist?(installer_dir)
    end

    def lsp_server_list_with_lang(lang)
      list = []
      LSP_SERVERS[lang].each do |s|
        list.push s['command']
      end
      list
    end

    def lsp_server_list
      list = []
      LSP_SERVERS.each_value do |l|
        l.each do |s|
          list.push s['command']
        end
      end
      list
    end

    def lsp_install_command(server)
      ext = '.sh'
      ext = '.cmd' unless File::ALT_SEPARATOR.nil?
      "#{lsp_installer_dir}/install-#{server}#{ext}"
    end

    def lsp_select_install_server(lang)
      server_list = lsp_server_list_with_lang(lang)
      @frame.echo_gets('server: ') do |input_text|
        comp_list = server_list.filter { |s| s.start_with? input_text }
        [comp_list.join(@frame.echo_win.sci_autoc_get_separator.chr), input_text.length]
      end
    end

    def lsp_select_lang_for_server
      lsp_lang_list = LSP_SERVERS.keys
      lang = if lsp_lang_list.include? @current_buffer.mode.name
               @current_buffer.mode.name
             else
               ''
             end
      @frame.echo_gets('language: ', lang) do |input_text|
        comp_list = lsp_lang_list.filter { |l| l.start_with? input_text }
        [comp_list.join(@frame.echo_win.sci_autoc_get_separator.chr), input_text.length]
      end
    end

    def lsp_start_installed_server(lang, command)
      server = LSP_SERVERS[lang].filter{ |s| s['command'] == command }[0]
      new_server_command = "#{lsp_server_dir(server['command'])}/#{server['command']}"
      if File.exist?(new_server_command)
        @ext.data['lsp'][lang] = LSP::Client.new(new_server_command, server['options'])
        Mrbmacs::LspExtension.set_keybind(self, lang)
      end
    end
  end
end
