require 'fileutils'
require 'open-uri'

module Conda
    "Prefix for installation of all the packages."
    PREFIX = File.absolute_path(File.join(File.dirname(__FILE__), "..", "usr"))

    "Prefix for the executable files installed with the packages"
    BINDIR = Gem.win_platform? ? File.join(PREFIX, "Library", "bin") : File.join(PREFIX, "bin")

    "Prefix for the library files installed with the packages"
    LIBDIR = Gem.win_platform? ? File.join(PREFIX, "Library", "lib") : File.join(PREFIX, "lib")

    "Prefix for the python scripts. On UNIX, this is the same than Conda.BINDIR"
    SCRIPTDIR = Gem.win_platform? ? File.join(PREFIX, "Scripts") : BINDIR

    "Prefix where the `python` command lives"
    PYTHONDIR = Gem.win_platform? ? PREFIX : BINDIR

    "Path to the `conda` binary"
    CONDA = Gem.win_platform? ? File.join(SCRIPTDIR, "conda.exe") : File.join(SCRIPTDIR, "conda")

    "Path to the condarc file"
    CONDARC = File.join(PREFIX, "condarc-ruby")

    """
    Use a cleaned up environment for the command `cmd`.
    Any environment variable starting by CONDA will interact with the run.
    """
    def Conda.run_in_env(cmd)
        env = ENV.to_hash
        to_remove = []
        for var in env.keys
            if var.start_with?("CONDA")
                to_remove << var
            end
        end
        for var in to_remove
            env[var] = nil
        end
        env["CONDARC"] = CONDARC
        ENV.replace(env)
        return `#{cmd}`
    end

    "Get the miniconda installer URL."
    def Conda._installer_url()
        res = "https://repo.continuum.io/miniconda/Miniconda3-latest-"
        if RbConfig::CONFIG["host"].include? "darwin"
            res += "MacOSX"
        elsif RbConfig::CONFIG["host"].include? "linux"
            res += "Linux"
        elsif Gem.win_platform?
            res += "Windows"
        else
            raise("Unsuported OS.")
        end
        res += (RbConfig::CONFIG["host"].include? "x86_64") ? "-x86_64" : "-x86"
        res += Gem.win_platform? ? ".exe" : ".sh"
        return res
    end

    "Install miniconda if it hasn't been installed yet; Conda._install_conda(true) installs Conda even if it has already been installed."
    def Conda._install_conda(force=false)

        if force || !(File.file? (CONDA))
            # Ensure PREFIX exists
            Dir.mkdir(PREFIX) unless File.exists?(PREFIX)
            print("Downloading miniconda installer ...\n")
            if Gem.win_platform?
                installer = File.join(PREFIX, "installer.exe")
            else
                installer = File.join(PREFIX, "installer.sh")
            end
            IO.copy_stream(open(Conda._installer_url()), installer)

            print("Installing miniconda ...\n")
            if Gem.win_platform?
                prefix = PREFIX.gsub("/", "\\")
                `#{installer} /S /AddToPath=0 /RegisterPython=0 /D=#{prefix} 1>&2`
            else
                `chmod 755 #{installer}`
                `#{installer} -b -f -p #{PREFIX}`
            end
            Conda.add_channel("defaults")
        end
    end

    "Install a new package."
    def Conda.add(pkg)
        Conda._install_conda()
        Conda.run_in_env("#{CONDA} install -y #{pkg} 1>&2")
    end

    "Uninstall a package."
    def Conda.rm(pkg)
        Conda._install_conda()
        run_in_env("#{CONDA} remove -y #{pkg} 1>&2")
    end

    "Update all installed packages."
    def Conda.update()
        Conda._install_conda()
        for pkg in Conda.installed_packages()
            run_in_env("#{CONDA} update -y #{pkg} 1>&2")
        end
    end

    "List all installed packages as an dict of tuples with (version_number, fullname)."
    def Conda.installed_packages_dict()
        Conda._install_conda()
        package_dict = {}
        for line in Conda.run_in_env("#{CONDA} list --export").split()
            if not line.start_with? "#"
                name, version, build_string = line.split("=")
                package_dict[name] = [Gem::Version.new(version), line]
            end
        end
        return package_dict
    end

    "List all installed packages as an array."
    def Conda.installed_packages()
        return Conda.installed_packages_dict().keys
    end

    "List all installed packages to standard output."
    def Conda.list()
        Conda._install_conda()
        Conda.run_in_env("#{CONDA} list 1>&2")
    end

    "Get the exact version of a package."
    def Conda.version(name)
        Conda._install_conda()
        packages = JSON.parse(run_in_env("#{CONDA} list --json"))
        for package in packages
            if package.startswith? name or package.include? "::#{name}"
                return package
            end
        end
        raise("Could not find the #{name} package")
    end

    "Search a specific version of a package"
    def Conda.search(pkg, ver=nil)
        Conda._install_conda()
        ret=JSON.parse(run_in_env("#{CONDA} search #{pkg} --json"))
        if ver == nil
            return ret.keys
        end
        out = []
        for k in ret.keys
            for i in ret[k].length
                if ret[k][i]["version"] == ver
                    out << k
                end
            end
        end
        out
    end

    "Check if a given package exists."
    def Conda.exists(package)
        if package.include? ("==")
          pkg,ver=package.split("==")  # Remove version if provided
          return Conda.search(pkg,ver).include? pkg
        else
          return Conda.search(package).include? package
        end
    end

    "Get the list of channels used to search packages"
    def Conda.channels()
        Conda._install_conda()
        ret=JSON.parse(Conda.run_in_env("#{CONDA} config --get channels --json"))
        if ret["get"].has_key? "channels"
            return ret["get"]["channels"]
        else
            return []
        end
    end

    "Add a channel to the list of channels"
    def Conda.add_channel(channel)
        Conda._install_conda()
        Conda.run_in_env("#{CONDA} config --add channels #{channel} --force")
    end

    "Remove a channel from the list of channels"
    def Conda.rm_channel(channel)
        Conda._install_conda()
        Conda.run_in_env("#{CONDA} config --remove channels #{channel} --force")
    end
end
