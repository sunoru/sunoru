using HTTP, JSON, YAML, OrderedCollections

const ProjectListData = joinpath(@__DIR__, "..", "data", "projects.yaml")
const ProjectListFile = joinpath(@__DIR__, "..", "projects.md")
const DefaultOwner = "sunoru"
const GitHubToken = get(ENV, "GITHUB_TOKEN", "")

function get_star(repo)
    r = HTTP.request(
        "GET", "https://api.github.com/repos/$repo",
        [
            "Accept" => "application/vnd.github+json",
            "Authorization" => "Bearer $GitHubToken",
        ]
    )
    data = String(r.body)
    JSON.parse(data)["stargazers_count"]
end

function main(verbose=true, skip_stars=false)

count = 0
stars = 0

data = YAML.load_file(ProjectListData; dicttype=OrderedDict{String,Any})

for subdata ∈ values(data)
    for project in subdata["projects"]
        repo, ignored = if project isa String
            if occursin('/', project)
                project
            else
                "$(DefaultOwner)/$project"
            end, false
        else
            project["repo"], get(project, "ignore-stars", false)
        end
        count += 1
        star = ignored || skip_stars ? 0 : get_star(repo)
        stars += star
        if verbose
            println("$count: $repo - $star")
        end
    end
end

@show count, stars

open(ProjectListFile, "w") do fo
    println(fo, """# スノル's Projects

| Projects | Stars |
|:-:|:-:|
| $count | $stars |""")

    for (key, subdata) ∈ data
        title = subdata["title"]
        println(fo, """\n<details id="$key" open>
  <summary><h2 style="display:inline-block">$title</h2></summary>""")
        for project in subdata["projects"]
            project = project isa String ? Dict("repo"=>project) : project
            repo = project["repo"]
            owner, name = occursin('/', repo) ? split(repo, '/') : (DefaultOwner, repo)
            url = get(project, "url", "https://github.com/$owner/$name")
            show_owner = get(project, "show-owner", false)
            src = "https://github-readme-stats.vercel.app/api/pin/?username=$owner&repo=$name&theme=radical"
            if show_owner
                src *= "&show_owner=true"
            end
            println(fo, """  <a href="$url" target="_blank">\n    <img align="center" src="$src" />\n  </a>""")
        end
        println(fo, "</details>")
    end
end

end

if abspath(PROGRAM_FILE) == @__FILE__
    main("--silent" ∉ ARGS, "--skip-stars" ∈ ARGS)
end
