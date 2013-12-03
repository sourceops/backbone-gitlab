# Client
# --------------------------------------------------------

GitLab = (url, token) ->

  root = @
  @url    = url
  @token  = token

  # Sync
  # --------------------------------------------------------

  @sync = (method, model, options) ->
    extendedOptions = undefined
    extendedOptions = _.extend(
      beforeSend: (xhr) ->
        xhr.setRequestHeader "PRIVATE-TOKEN", root.token if root.token
    , options)
    Backbone.sync method, model, extendedOptions
  
  @Model = Backbone.Model.extend(sync: @sync)
  @Collection = Backbone.Collection.extend(sync: @sync)
  
  # Users
  # --------------------------------------------------------
  
  @User = @Model.extend(
    backboneClass: "User"
    url: -> "#{root.url}/user"
    initialize: ->
      @sshkeys = new root.SSHKeys()
  )
  
  # SSH Keys
  # --------------------------------------------------------
  
  @SSHKey = @Model.extend(
    backboneClass: "SSHKey"
  )
  
  @SSHKeys = @Collection.extend(
    backboneClass: "SSHKeys"
    url: -> "#{root.url}/user/keys"
    model: root.SSHKey
  )
  
  # Project
  # --------------------------------------------------------
  
  @Project = @Model.extend(
    backboneClass: "Project"
    url: -> "#{root.url}/projects/#{@id || @escaped_path()}"
    initialize: ->
      @branches = new root.Branches([], project:@)
      @members = new root.Members([], project:@)
      @on("change", @parsePath)
      @parse_path()
    tree: (path, branch) ->
      return new root.Tree([], 
        project:@
        path: path
        branch: branch
      )
    blob: (path, branch) ->
      return new root.Blob(
        file_path: path
      ,
        branch: branch
        project:@
      )
    parse_path: ->
      if @get("path_with_namespace")
        split = @get("path_with_namespace").split("/")
        @set("path", _.last(split))
        @set("owner", { username: _.first(split) })
    escaped_path: ->
      return @get("path_with_namespace").replace("/", "%2F")
  )
  
  # Branches
  # --------------------------------------------------------
  
  @Branch = @Model.extend(
    backboneClass: "Branch"
  )
  
  @Branches = @Collection.extend(
    backboneClass: "Branches"
    model: root.Branch
  
    url: -> "#{root.url}/projects/#{@project.escaped_path()}/repository/branches"
    
    initialize: (models, options) ->
      options = options || {}
      if !options.project then throw "You have to initialize GitLab.Branches with a GitLab.Project model"
      @project = options.project
  )

  # Members
  # --------------------------------------------------------
  
  @Member = @Model.extend(
    backboneClass: "Member"
  )
  
  @Members = @Collection.extend(
    backboneClass: "Members"
    url: -> "#{root.url}/projects/#{@project.escaped_path()}/members"
    initialize: (models, options) ->
      options = options || {}
      if !options.project then throw "You have to initialize GitLab.Members with a GitLab.Project model"
      @project = options.project
    model: root.Member
  )

  # Blob
  # --------------------------------------------------------
  
  @Blob = @Model.extend(
    
    backboneClass: "Blob"
  
    initialize: (data, options) ->
      options = options || {}
      if !options.project then throw "You have to initialize GitLab.Blob with a GitLab.Project model"
      @project = options.project
      @branch = options.branch || "master"
      @on("sync", -> @set("id", "fakeIDtoenablePUT"))
      @on("change", @parseFilePath)
      @parseFilePath()
  
    parseFilePath: (model, options) ->
      if @get("file_path")
        @set("name", _.last(@get("file_path").split("/")))
  
    sync: (method, model, options) ->
      options = options || {}
      baseURL = "#{root.url}/projects/#{@project.escaped_path()}/repository"
      if method.toLowerCase() == "read"
        options.url = "#{baseURL}/blobs/#{@branch}"
      else
        options.url = "#{baseURL}/files"
      root.sync.apply(this, arguments)
  
    toJSON: ->
      {
        file_path: @get("file_path")
        branch_name: @branch
        content: @get("content")
        commit_message: @get("commit_message") || @defaultCommitMessage()
      }
    
    defaultCommitMessage: ->
      if @isNew()
        "Created #{@get("file_path")}"
      else
        "Updated #{@get("file_path")}"
    
    fetchContent: (options) ->
      @fetch(
        _.extend(
          dataType:"html"
          data: filepath: @get("file_path")
        , options)
      )
  
    parse: (response, options) ->
      # if response is blob content from /blobs
      if _.isString(response)
        content: response
      # if response is blob object from /files
      else
        response
  )

  # Tree
  # --------------------------------------------------------
  
  @Tree = @Collection.extend(
    
    backboneClass: "Tree"
    model: root.Blob
    url: -> "#{root.url}/projects/#{@project.escaped_path()}/repository/tree"
    
    initialize: (models, options) ->
      options = options || {}
      if !options.project then throw "You have to initialize GitLab.Tree with a GitLab.Project model"
      @project = options.project
      @path = options.path
      @branch = options.branch || "master"
      @trees = []
  
    fetch: (options) ->
      options = options || {}
      options.data = options.data || {}
      options.data.path = @path if @path
      options.data.ref_name = @branch
      root.Collection.prototype.fetch.apply(this, [options])
    
    parse: (resp, xhr) ->
      
      # add trees to trees. we're loosing the tree data but the path here.
      _(resp).filter((obj) =>
        obj.type == "tree"
      ).map((obj) => @trees.push(@project.tree(obj.name, @branch)))
  
      # add blobs to models. we're loosing the blob data but the path here.
      _(resp).filter((obj) =>
        obj.type == "blob"
      ).map((obj) => 
        full_path = []
        full_path.push @path if @path
        full_path.push obj.name
        @project.blob(full_path.join("/"), @branch)
      )
  )
  
  # Initialize
  # --------------------------------------------------------

  @user   = new @User()

  @project = (full_path) ->
    return new @Project(
      path: full_path.split("/")[1]
      path_with_namespace: full_path
    )
  
  return @

window.GitLab = GitLab