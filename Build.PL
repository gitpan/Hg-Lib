use Module::Build;

use File::Which;

die( "Cannot find Mercurial executable (hg) in path\n" )
  unless +which( 'hg' );

Module::Build->new(

    dist_name   => 'Hg-Lib',
    module_name => 'Hg::Lib',
    license     => 'perl',

    configure_requires => {
        'Module::Build' => 0,
        'File::Which'   => 0,
    },

    requires => {
        'Capture::Tiny'            => 0,
        'Exporter'                 => 0,
        'Exporter::Tiny'           => 0,
        'File::Which'              => 0,
        'FileHandle'               => 0,
        'IO::Select'               => 0,
        'Moo'                      => '1.003000',
        'MooX::Attributes::Shadow' => '0.03',
        'System::Command'          => 0,
        'Throwable'                => 0,
        'Try::Tiny'                => 0,
        'Type::Library'            => 0.028,
        'Type::Params'             => 0.028,
        'Type::Tiny'               => 0.028,
        'Type::Utils'              => 0.028,
        'Types::Standard'          => 0.028,
        'autodie'                  => 0,
        'boolean'                  => 0,
        'feature'                  => 0,
        'perl'                     => '5.10.1',
    },

    (
        Module::Build->VERSION < 4.004
        ? 'build_requires'
        : 'test_requires'
      ) => {
        'Capture::Tiny'         => 0,
        'File::Spec::Functions' => 0,
        'File::Which'           => 0,
        'File::pushd'           => 0,
        'Getopt::Long'          => 0,
        'IO::Handle'            => 0,
        'Moo'                   => '1.003000',
        'Moo::Role'             => '1.003000',
        'Probe::Perl'           => 0,
        'Safe::Isa'             => 0,
        'Sub::Quote'            => 0,
        'Test::Class'           => 0,
        'Test::Directory'       => 0,
        'Test::Fatal'           => 0,
        'Test::File'            => 0,
        'Test::Lib'             => 0,
        'Test::More'            => 0,
        'Test::Roo'             => 0,
        'Test::Roo::Role'       => 0,
        'Type::Params'          => 0,
        'YAML::Tiny'            => 0,
        'boolean'               => 0,
      },

    meta_merge => {
        resources => {
            repository => 'https://bitbucket.org/djerius/hg-lib',
        }
    },

    create_license       => 1,
    create_readme        => 1,
    recursive_test_files => 1,

)->create_build_script;
