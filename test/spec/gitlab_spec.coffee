ajaxTimeout = 2000

describe("GitLab", ->

  # GitLab
  # ----------------------------------------------------------------

  it("should set default variables", ->
    expect(GitLab.token).toBe(null)
    expect(GitLab.url).toBe(null)
    expect(GitLab.version).toBe("v3")
  )

  it("should save settings", ->
    GitLab.token = "abcdefg"
    GitLab.url = "https://gitlab.com/api"
    expect(GitLab.token).toBe("abcdefg")
    expect(GitLab.url).toBe("https://gitlab.com/api")
  )

  # GitLab.User
  # ----------------------------------------------------------------

  describe("GitLab.Users", ->

    beforeEach(->
      GitLab.token = "abcdefg"
      GitLab.url = "locahost:5000"
    )

    it("should fetch users", ->
      users = new GitLab.Users()
      users.fetch()
      
      waitsFor(-> 
        return users.length > 0
      , "Users never loaded", ajaxTimeout
      )

      runs(->
        expect(users.length).toEqual(2);
      )
    )

  )  
)