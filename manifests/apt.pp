# == Class: duo_unix::apt
#
# Provides duo_unix for an apt-based environment (e.g. Debian/Ubuntu)
#
# === Authors
#
# Mark Stanislav <mstanislav@duosecurity.com>
#
class duo_unix::apt {
  $repo_file = '/etc/apt/sources.list.d/duosecurity.list'
  $repo_uri  = 'http://pkg.duosecurity.com'
  $package_state = $::duo_unix::package_version

  if $::duo_unix::manage_ssh {
    package { 'openssh-server':
      ensure => installed;
    }
  }

  package { $duo_unix::duo_package:
    ensure  => $package_state
  }

  if $duo_unix::manage_repo {
    file { $repo_file:
      owner   => 'root',
      group   => 'root',
      mode    => '0644',
      content => "deb ${repo_uri}/${::operatingsystem} ${::lsbdistcodename} main",
      notify  => Exec['duo-security-apt-update'],
      before  => Package[$duo_unix::duo_package]
    }

    exec { 'duo-security-apt-update':
      command     => '/usr/bin/apt-get update',
      refreshonly => true,
      require     => File[$repo_file],
      before      => Package[$duo_unix::duo_package]
    }

    exec { 'Duo Security GPG Import':
      command => '/usr/bin/apt-key add /etc/apt/DEB-GPG-KEY-DUO',
      unless  => '/usr/bin/apt-key list | grep "Duo Security"',
      notify  => Exec['duo-security-apt-update'],
      before  => Package[$duo_unix::duo_package]
    }
  }
}
