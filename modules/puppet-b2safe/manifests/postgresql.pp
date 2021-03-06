class puppet-b2safe::postgresql(
$db_password       ='irods',
$db_user           ='irods',
$DATABASEHOSTORIP  = 'localhost',
$DATABASEPORT      = '0000',
$DATABASENAME      = 'ICAT',

)
{

  notify {"IN POSTGRESQL":}

#======================================================
#Install all required postgresql
#======================================================
 ensure_packages(['authd','unixODBC','unixODBC-devel'])

 package{'postgresql93-server':
  ensure  => installed,
  require => Package ['authd','unixODBC','unixODBC-devel'],
  provider => 'yum',
  }->

package{'postgresql93-odbc':
  ensure  => installed,
  require => Package ['authd','unixODBC','unixODBC-devel'],
  provider => 'yum',
  }->

package { 'irods-database-plugin-postgres93':
    provider => rpm,
    ensure   => installed,
    source   => "ftp://ftp.renci.org/pub/irods/releases/4.1.5/centos6/irods-database-plugin-postgres93-1.6-centos6-x86_64.rpm",
    require  =>Package['irods-icat-4.1.5']
   }  ->

  exec{'initdb':
   path    => '/bin:/usr/bin:/sbin:/usr/sbin',
   command => 'service postgresql-9.3 initdb'
  } ->

exec{'postgresql-9.3':
   path    => '/bin:/usr/bin:/sbin:/usr/sbin',
   command => 'service postgresql-9.3 start',
   require => Exec['initdb']
  } ->



#=====================================================
#Setup ICAT DB, user access and grant priviledges 
#=====================================================

 file{'/var/lib/pgsql/9.3/data/pg_hba.conf':
  ensure => present,
  owner  => 'postgres',
  group  => 'postgres',
  source => 'puppet:///modules/puppet-b2safe/pg_hba.conf',
  }->


 service{'postgresql-9.3':
  ensure  => 'running',
  subscribe => File['/var/lib/pgsql/9.3/data/pg_hba.conf']
  }->

 exec{'setup_ICAT_DB':
  unless  => "/usr/pgsql-9.3/bin/psql -U postgres --list |grep ICAT",
  #unless  => "/usr/pgsql-9.3/bin/psql -U postgres -lqt | cut -d \| -f 1 | grep -w icat |wc -l" 
  command => "/usr/pgsql-9.3/bin/psql -U postgres -c 'CREATE DATABASE \"ICAT\"'",
 }->

 exec{'add_user':
  unless  => "/usr/pgsql-9.3/bin/psql -U postgres -c \"SELECT 1 FROM pg_roles WHERE rolname='${db_user}'\" |grep 1",
  command => "/usr/pgsql-9.3/bin/psql -U postgres -c \"CREATE USER ${db_user} WITH PASSWORD '${db_password}'\"",
 }->

exec{'grand_priv':
  command => "/usr/pgsql-9.3/bin/psql -U postgres -c 'GRANT ALL PRIVILEGES ON DATABASE \"ICAT\" TO ${db_user}\'",
 }->

#======================================================
# Copy configuration file for the Database 
#======================================================


file { '/var/lib/irods/packaging/setup_irods_database.sh':
    ensure  => file,
    owner   => 'root',
    group   => 'root',
    mode    => '0755',
    content => template('puppet-b2safe/setup_irods_database.erb'),
    }

}





















