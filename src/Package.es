/*
    Package.es -- Pak package description class
 */

module ejs.pak {

require ejs.unix
require ejs.version

enumerable class Package {
    use default namespace public
    var args: String            //  Original full args provided to specify the pak when constructed
    var name: String            //  Bare name without version information
    var dirty: Boolean          //  Cache dom is dirty and must be saved
    var cache: Object           //  Package description from cache
    var cachePath: Path?        //  Path to pak in cache (includes version)
    var cached: Boolean         //  True if present in the cache
    var catalog: String?        //  Catalog to search for the pak
    var endpoint: String?       //  Package endpoint. Typically a github "owner/repo" or "@npm/name"
    var installPath: Path?      //  Path to installed copy of the pak
    var installed: Boolean      //  True if installed locally
    var install: Object         //  Package description from installed paks
    var origin: String?         //  Package endpoint origin (owner/repository)
    var source: Object          //  Package description from source
    var sourcePath: Path        //  Source for the package
    var sourced: Boolean        //  True if source present
    var download: String        //  URI to download a version
    var protocol: String?       //  Protocol to use to access repository. Null if local.
    var host: String?           //  Host storing the repository
    var owner: String?          //  Repository owner account "owner/name"
    var override: Object?       //  Override configuration
    var repository: Path?       //  Repository name
    var versions: Array?        //  List of available versions
    var installVersion: Version?
    var sourceVersion: Version?
    var cacheVersion: Version?
    var remoteVersion: Version?
    var remoteTag: String?
    var versionCriteria: String?

    /*
        Create a pak description object and resolve as fully as possible.
        Pathname may be a filename, URI, pak name or a versioned pak name
        Formats:
            http://host/..../name
            http://host/..../name.git
            git@github.com:embedthis/name
            git@github.com:embedthis/name.git
            github-account/name
            name
            name#1.2.3
            ./path/to/directory
            /path/to/directory
     */
    function Package(ref: String, criteria = null) {
        this.args = ref
        if (criteria) {
            versionCriteria = criteria
        } else if (ref.contains('#')) {
            [ref, versionCriteria] = ref.split('#')
        }
        versionCriteria ||= '^*'
        parseEndpoint(ref)
        resolve()
    }

    /*
        Parse the endpoint reference. Supported formats:
            name
            name#1.2.3
            http://host/..../name
            http://host/..../name.git
            git@github.com:embedthis/name
            git@github.com:embedthis/name.git
            github-account/name
            @npm/name
            /.../paks/NAME/ACCOUNT/VERSION
            ./src/paks/NAME
            ./path/to/directory
            /path/to/directory
     */
    function parseEndpoint(ref: String) {
        if (ref.contains('#')) {
            [ref, this.versionCriteria] = ref.split('#')
        }
        ref = ref.trimEnd('.git')
        let matches = RegExp('^(npm:)|(pak:)|(bower:)').exec(ref)
        if (matches) {
            [this.catalog, ref] = ref.split(':')
        }
        if (ref.contains('://')) {
            /* http:// */
            matches = RegExp('([^:]+):\/\/([^\/]+)\/([^\/]+)\/([^\/]+)').exec(ref)

        } else if (ref.contains('git@')) {
            /* git@host */
            matches = RegExp('([^@]+)@([^\/]+):([^\/]+)\/([^\/]+)').exec(ref)

        } else if (Path(ref).isAbsolute || ref[0] == '.') {
            /* Source package */
            let package = Package.loadPackage(ref)
            if (package) {
                if (package.pak && package.pak.origin) {
print("SOURCE ORIGIN")
                    parseEndpoint(package.pak.origin)
                } else if (package.repository) {
                    parseEndpoint(package.repository.url)
                } else {
                    /* MOB - Unreliable? - who is using */
                    print("WARNING UNRELIABLE", ref)
                    [repository,owner,] = Path(ref).components.slice(-3)
                    origin = owner + '/' + repository
                }
                if (package.version) {
                    setCacheVersion(package.version)
                }
            }
            matches = []

        } else if (ref.startsWith('@')) {
            origin = ref
            [owner, repository] = origin.split('/')
            if (owner == '@npm') {
                catalog = 'npm'
            }
            name = repository
            matches = []

        } else if (ref.match(/\//)) {
            /* github-account */
            matches = RegExp('([^\/]+)\/([^\/]+)').exec(ref)
            if (matches) {
                ref = Path('https://github.com/' + ref)
                matches = [null, 'https', 'github.com' ] + matches.slice(1)
            }

        } else {
            /* Simple name */
            name ||= ref
            repository = ref
            if (catalog == 'npm') {
                owner = '@npm'
                origin = '@npm/' + ref
            }
            matches = []
        }
        if (!matches) {
            throw 'Bad pak address "' + ref + '"'
        }
        if (matches.length >= 5) {
            endpoint = ref
            [,protocol,host,owner,repository] = matches
            origin = owner + '/' + repository
        }
    }

    /*
        Resolve as much as we can about a package. A package may be cached and/or installed locally.
     */
    function resolve(criteria = null) {
        if (criteria) {
            versionCriteria = criteria
        }
        if (name) {
            /*
                Already have a name, so check if installed locally and extract the origin in the cache
             */
            setInstallPath()
            if (installPath && installPath.exists) {
                install = Package.loadPackage(installPath)
                if (install) {
                    installVersion = Version(install.version || '0.0.1')
                    if (install.pak && install.pak.origin) {
                        parseEndpoint(install.pak.origin)
                    }
                }
            }
        }
        if (versionCriteria) {
            selectCacheVersion(versionCriteria)
        } else if (cacheVersion) {
            setCachePath()
        }
        if (cachePath && cachePath.exists) {
            cache = Package.loadPackage(cachePath, {quiet: true})
            if (cache) {
                name ||= cache.name
                if (cache.version) {
                    cacheVersion = Version(cache.version)
                }
                setInstallPath()
                if (installPath && installPath.exists) {
                    install = Package.loadPackage(installPath)
                    if (install) {
                        installVersion = Version(install.version || '0.0.1')
                    }
                }
                if (cache.pak is String) {
                    trace('Warn', 'Using deprecated "pak" version property. Use "pak.version" instead in ' +
                        cachePath)
                }
            }
        }
        if (sourcePath && sourcePath.exists) {
            source = Package.loadPackage(sourcePath)
            if (source) {
                sourceVersion = Version(source.version || '0.0.1')
            }
        }
    }

    function selectCacheVersion(criteria: String) {
        if (!cacheVersion || !cacheVersion.acceptable(criteria)) {
            /*
                Pick most recent qualifying version
             */
            let base = repository + '/' + (owner || '*')
            for each (filename in Version.sort(find(App.config.directories.pakcache, base + '/*'), -1)) {
                let candidate = Version(filename.basename)
                if (candidate.acceptable(criteria)) {
                    cacheVersion = candidate
                    owner = filename.dirname.basename
                    origin = owner + '/' + repository
                    break
                }
            }
        }
        setCachePath()
    }

    function setCachePath() {
        cachePath = null
        cached = false
        if (cacheVersion && cacheVersion.valid) {
            let cacheBase = repository.join(owner, cacheVersion.toString())
            cachePath = App.config.directories.pakcache.join(cacheBase)
            if (cachePath.exists && Package.loadPackage(cachePath, {quiet: true})) {
                cached = true
            }
        }
    }

    function setDownload(uri: String) {
        download = uri
    }

    function setCacheVersion(ver: String?) {
        if (ver) {
            cacheVersion = Version(ver)
            setCachePath()
        } else {
            cacheVersion = null
        }
    }

    public function setInstallPath() {
        installPath = App.config.directories.paks.join(name)
        installed = (installPath.exists && installPath.join('package.json').exists)
    }

    function setInstalledVersion(ver: String?) {
        if (ver) {
            installVersion = Version(ver)
        } else {
            installVersion = null
        }
    }

    function setRemoteVersion(ver: String?) {
        remoteTag = ver
        if (ver) {
            remoteVersion = Version(ver)
        } else {
            remoteVersion = null
        }
    }

    function setCatalog(catalog: String) {
        this.catalog = catalog
    }

    function setVersionCriteria(criteria: String) {
        versionCriteria = criteria
        selectCacheVersion(versionCriteria)
    }

    function setSource(sourcePath: Path) {
        if (!sourcePath.exists && Package.getSpecFile(sourcePath)) {
            throw 'Pak source at ' + sourcePath + ' is missing package.json'
            return
        }
        this.sourcePath = sourcePath
        sourced = sourcePath.exists
        source = Package.loadPackage(sourcePath)
        if (source) {
            sourceVersion = Version(source.version || '0.0.1')
            setCacheVersion(source.version)
            if (source.repository) {
                parseEndpoint(source.repository.url)
                resolve()
            }
        }
    }

    static function loadPackage(path: Path?, options = {}): Object {
        if (!path) {
            return null
        }
        for each (name in PakFiles) {
            let f = path.join(name)
            if (f.exists) {
                let obj = deserialize(f.readString())
                obj.dependencies ||= {}
                obj.optionalDependencies ||= {}
                obj.pak ||= {}
                if (name == 'bower.json') {
                    print('WARNING: using bower.json for ' + path)
                }
                return obj
            }
        }
        return null
    }

//  MOB - rename getPackageFilename
    public static function getSpecFile(path: Path): Path? {
        for each (pname in PakFiles) {
            let f = path.join(pname)
            if (f.exists) {
                return f
            }
        }
        return null
    }

    public function toString() name || ''

    public function show(msg: String = '') {
        print(msg + serialize(this, {hidden: true, pretty: true}))
    }

} /* class Package */
} /* ejs.pak */
