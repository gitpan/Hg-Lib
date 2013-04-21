use Module::Build;

Module::Build->new(

    module_name => 'Hg::Lib',
    license     => 'perl',

    requires => {
        'IO::Handle'               => 0,
        'IPC::Open2'               => 0,
        'Moo'                      => '1.001000',
        'MooX::Attributes::Shadow' => 0,
        'MooX::Types::MooseLike'   => 0,
        'POSIX'                    => 0,
        'Params::Validate'         => 0,
        'Scalar::Util'             => 0,
        'Try::Tiny'                => 0,
    },

    test_requires => {
        'Getopt::Long'    => 0,
        'IO::Handle'      => 0,
        'IO::Pipe'        => 0,
        'Moo::Role'       => 0,
        'Probe::Perl'     => 0,
        'Sub::Quote'      => 0,
        'Test::Exception' => 0,
        'Test::More'      => 0,
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
