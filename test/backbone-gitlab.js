// Generated by CoffeeScript 1.6.3
(function() {
  window.GitLab = {};

  GitLab.url = null;

  GitLab.sync = function(method, model, options) {
    var extendedOptions;
    extendedOptions = void 0;
    extendedOptions = _.extend({
      beforeSend: function(xhr) {
        if (GitLab.token) {
          return xhr.setRequestHeader("PRIVATE-TOKEN", GitLab.token);
        }
      }
    }, options);
    return Backbone.sync(method, model, extendedOptions);
  };

  GitLab.Model = Backbone.Model.extend({
    sync: GitLab.sync
  });

  GitLab.Collection = Backbone.Collection.extend({
    sync: GitLab.sync
  });

  GitLab.User = GitLab.Model.extend({
    backboneClass: "User",
    url: function() {
      return "" + GitLab.url + "/user";
    },
    initialize: function() {
      return this.sshkeys = new GitLab.SSHKeys();
    }
  });

  GitLab.SSHKey = GitLab.Model.extend({
    backboneClass: "SSHKey"
  });

  GitLab.SSHKeys = GitLab.Collection.extend({
    backboneClass: "SSHKeys",
    url: function() {
      return "" + GitLab.url + "/user/keys";
    },
    model: GitLab.SSHKey
  });

  GitLab.Project = GitLab.Model.extend({
    backboneClass: "Project",
    url: function() {
      return "" + GitLab.url + "/projects/" + (this.id || this.escaped_path());
    },
    initialize: function() {
      this.branches = new GitLab.Branches([], {
        project: this
      });
      return this.members = new GitLab.Members([], {
        project: this
      });
    },
    escaped_path: function() {
      return this.get("path_with_namespace").replace("/", "%2F");
    }
  });

  GitLab.Branch = GitLab.Model.extend({
    backboneClass: "Branch"
  });

  GitLab.Branches = GitLab.Collection.extend({
    backboneClass: "Branches",
    url: function() {
      return "" + GitLab.url + "/projects/" + (this.project.escaped_path()) + "/repository/branches";
    },
    initialize: function(models, options) {
      return this.project = options.project;
    },
    model: GitLab.Branch
  });

  GitLab.Member = GitLab.Model.extend({
    backboneClass: "Member"
  });

  GitLab.Members = GitLab.Collection.extend({
    backboneClass: "Members",
    url: function() {
      return "" + GitLab.url + "/projects/" + (this.project.escaped_path()) + "/members";
    },
    initialize: function(models, options) {
      return this.project = options.project;
    },
    model: GitLab.Member
  });

  GitLab.Client = function(token) {
    this.token = token;
    this.user = new GitLab.User();
    this.project = function(full_path) {
      return new GitLab.Project({
        path: full_path.split("/")[1],
        path_with_namespace: full_path
      });
    };
    return this;
  };

}).call(this);
