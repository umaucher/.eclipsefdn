# Overview, Defaults, Reference see https://otterdog.eclipse.org/projects/automotive.score

local orgs = import 'vendor/otterdog-defaults/otterdog-defaults.libsonnet';

local default_review_rule = {
  # dismiss approved reviews automatically when a new commit is pushed
  dismisses_stale_reviews: true,

  # The number of approvals required before a pull request can be merged [0,10]
  required_approving_review_count: 1,

  # require an approved review in pull requests including files with a designated code owner
  requires_code_owner_review: true,

  # TODO: the most recent push must be approved by someone other than the person who pushed it
  # requires_last_push_approval: true,
};

local main_branch_protection_rule = orgs.newBranchProtectionRule('main') {
  # Enforce branch is up-to-date before merging
  requires_status_checks: true,
  requires_strict_status_checks: true,
  # Restrict merge commits
  requires_linear_history: true,
  # Match the default_review_rule, otherwise it is overwritten with 2
  required_approving_review_count: 1,
};

local block_tagging(tags, bypass) =
 orgs.newRepoRuleset('tags-protection') {
  target: "tag",
  # bot has admin access anyway, but let's be explicit
  bypass_actors+: bypass, # + ["@eclipse-score-bot"] # Bypass_actors cannot be individuals, only role, team, or App: https://otterdog.readthedocs.io/en/latest/reference/organization/repository/bypass-actor/
  include_refs+: [std.format("refs/tags/%s", tag) for tag in tags],
  allows_creations: false,
  allows_deletions: false,
  allows_updates: false,

  # Those are not needed. Override in order to drop the defaults.
  required_pull_request: null,
  required_status_checks: null,
};

# This list is generated with the detect_languages.py script.
# There is no fancy automation, just run the script and copy-paste the output here when you want to update it.
local active_languages = {
  ".eclipsefdn": ['actions', 'python'],
  ".github": ['actions', 'javascript-typescript', 'python'],
  "apt-install": ['actions'],
  "baselibs": ['actions', 'c-cpp'],
  "bazel-tools-cc": ['actions', 'c-cpp', 'python'],
  "bazel-tools-python": ['actions', 'python'],
  "bazel_cpp_toolchains": ['actions', 'c-cpp'],
  "bazel_platforms": ['actions'],
  "bazel_registry": ['actions', 'python'],
  "bazel_registry_ui": ['actions', 'javascript-typescript'],
  "cicd-actions": ['actions', 'javascript-typescript'],
  "cicd-workflows": ['actions'],
  "communication": ['actions', 'c-cpp', 'python'],
  "config_management": ['actions', 'c-cpp'],
  "dash-license-scan": ['actions', 'python'],
  "dev_playground": ['actions', 'c-cpp'],
  "devcontainer": ['actions', 'python'],
  "docs-as-code": ['actions', 'python'],
  "eclipse-score-website": ['actions', 'javascript-typescript'],
  "eclipse-score-website-preview": ['actions'],
  "eclipse-score-website-published": ['actions', 'javascript-typescript'],
  "eclipse-score.github.io": ['actions', 'python'],
  "feo": ['actions', 'c-cpp'],
  "ferrocene_toolchain_builder": ['actions', 'python'],
  "inc_daal": ['actions', 'c-cpp'],
  "inc_diagnostics": ['actions', 'c-cpp'],
  "inc_security_crypto": ['actions', 'c-cpp', 'python'],
  "inc_someip_gateway": ['actions', 'c-cpp', 'python'],
  "infrastructure": ['actions', 'python'],
  "itf": ['actions', 'python'],
  "kyron": ['actions', 'python'],
  "lifecycle": ['actions', 'c-cpp'],
  "logging": ['actions', 'c-cpp'],
  "mcp-servers": ['actions', 'python'],
  "module_template": ['actions', 'c-cpp'],
  "more-disk-space": ['actions', 'javascript-typescript'],
  "nlohmann_json": ['actions', 'c-cpp', 'python'],
  "orchestrator": ['actions', 'python'],
  "os_autosd": ['actions'],
  "os_images": ['actions', 'python'],
  "persistency": ['actions', 'c-cpp', 'python'],
  "process_description": ['actions', 'javascript-typescript'],
  "qnx_unit_tests": ['actions', 'c-cpp'],
  "reference_integration": ['actions', 'c-cpp', 'python'],
  "rules_imagefs": ['actions'],
  "rules_rust": ['actions'],
  "sbom-tool": ['actions', 'python'],
  "score": ['actions'],
  "score-crates": ['actions'],
  "score_cpp_policies": ['actions', 'c-cpp'],
  "score_rust_policies": ['actions'],
  "scrample": ['actions', 'c-cpp', 'go'],
  "testing_tools": ['actions', 'c-cpp', 'python'],
  "time": ['actions', 'c-cpp', 'python'],
  "toolchains_gcc": ['actions', 'c-cpp'],
  "toolchains_gcc_packages": ['actions'],
  "toolchains_qnx": ['actions', 'python'],
  "toolchains_rust": ['actions'],
  "tooling": ['actions', 'python'],
  "tools": ['actions', 'python'],
};

// Hint: Override all options as required when creating a new repository. See below for examples.
// Parameters:
//   name: The name of the repository.
//   pages: boolean, whether to create default documentation pages for the repository.
//   category: Optional string stored as a "category" custom property, used for grouping repositories in the auto-generated organization README file.
//   subcategory: Optional string stored as a "subcategory" custom property, used for further grouping within a category.
local newScoreRepo(name, pages = false, category = null, subcategory = null) =
  local cat = if category != null && subcategory != null then {
      category: category,
      subcategory: subcategory
    } else if category != null then {
      category: category,
    } else if subcategory != null then
      error "Subcategory requires a category. Repository: " + name
    else {};

  orgs.newRepo(name) {
    // These are disabled by default
    dependabot_security_updates_enabled: true,

    // Default: Squash only.
    // More details: https://eclipse-score.github.io/score/main/contribute/general/git.html
    allow_rebase_merge: false,
    allow_merge_commit: false,
    allow_squash_merge: true,

    // Remove some features, to avoid having too many options where stuff is located
    has_discussions: false,
    has_projects: false,
    has_wiki: false,

    // Setup the default review rule for main branch.
    rulesets: [
      orgs.newRepoRuleset('main') {
        include_refs+: [
          "~DEFAULT_BRANCH"
        ],
        required_pull_request+: default_review_rule,
      },
    ],

    custom_properties+: cat,
  } + if pages then {
    gh_pages_build_type: "workflow",
    homepage: "https://eclipse-score.github.io/" + name,
  } else {};

# As Otterdog does not support environment secrets yet, we need to specify the repositories that should have access to the QNX secrets here.
# That's not ideal, as any workflow, regardless of environment approval can access the secrets, but it's the best we can do for now.
# Issue: https://github.com/eclipse-csi/otterdog/issues/537
local qnx_enabled_repos = [
    "baselibs_rust",
    "baselibs",
    "bazel_cpp_toolchains",
    "communication",
    "ferrocene_toolchain_builder",
    "inc_security_crypto",
    "inc_someip_gateway",
    "itf",
    "kyron",
    "lifecycle",
    "logging",
    "orchestrator",
    "persistency",
    "qnx_unit_tests",
    "reference_integration",
    "rules_imagefs",
    "scrample",
    "time",
    "toolchains_qnx",
    "config_management",
];


# These requirements will store the QNX secrets.
# For now, as stated above, these simply guard execution of selected workflows.
# Note: we'll discuss 'workflow-approval' vs 'qnx-approval', once more use cases arise.
local qnx_environments = [
  orgs.newEnvironment('workflow-approval') {
    deployment_branch_policy: "all",
    reviewers+: [
      "@eclipse-score/automotive-score-committers",
    ],
  },
];

# Repositories that are based on the module_template and offer GitHub Pages for documentation
# should use this function, as it includes the necessary settings for both.
# Parameters:
#   name:        Name of the repository.
#   subcategory: Optional string stored as a "subcategory" custom property alongside "category".
#                This helper always sets the category to "modules", so the effective
#                category is conceptually either "modules" (no subcategory) or
#                "modules.<subcategory>" when a subcategory is given.
local newDependableElementRepo(name, subcategory = null) = newScoreRepo(name, pages = true, category = "modules", subcategory = subcategory) {
  template_repository: "eclipse-score/module_template",
  environments+: qnx_environments,
  workflows+: {
    max_cache_size_gb: 50,
  }
};

# Repositories owned or maintained by the infrastructure community should use this helper.
# Parameters:
#   name:        Name of the repository.
#   pages:       Boolean, whether to enable GitHub Pages defaults (see newScoreRepo).
#   subcategory: Optional string stored as a "subcategory" custom property alongside "category".
#                This helper always sets the category to "infrastructure", so the effective
#                category is conceptually either "infrastructure" (no subcategory) or
#                "infrastructure.<subcategory>" when a subcategory is given.
local newInfrastructureTeamRepo(name, pages = false, subcategory = null) =
  newScoreRepo(name, pages = pages, category = "infrastructure", subcategory = subcategory)
  {
    # enable github code scanning for infrastructure repositories that have active languages
    code_scanning_default_setup_enabled: std.objectHas(active_languages, name),
    code_scanning_default_languages+: std.get(active_languages, name, []),
  };

# Publication to pypi can only be triggered by infrastructure-maintainers and only from main branch or tag
local pypi_infra_env = orgs.newEnvironment('pypi') {
  // Note: we cannot use @eclipse-score/infrastructure-maintainers here,
  // because the team does not have write access, only the members.
  reviewers+: [
    "@AlexanderLanin",
    "@dcalavrezo-qorix",
    "@MaximilianSoerenPollak",
    "@nradakovic",
  ],
  deployment_branch_policy: "selected",
  branch_policies+: [
    "main",
    "tag:v*",
  ],
};

orgs.newOrg('automotive.score', 'eclipse-score') {
  settings+: {
    name: "Eclipse S-CORE",
    description: "",
    discussion_source_repository: "eclipse-score/score",
    has_discussions: true,

    custom_properties+: [
      # This is used to categorize repositories for the auto-generated organization README file.
      # The subcategory is optional and can be used to further categorize repositories. For example, "infrastructure.bazel" or "modules.communication".
      orgs.newCustomProperty('category') {
        description: "Category used to group repositories in the auto-generated organization README file",
        value_type: "string",
      },
      orgs.newCustomProperty('subcategory') {
        description: "Subcategory used to further group repositories within a category in the auto-generated organization README file",
        value_type: "string",
      },
    ],
    workflows+: {
      max_cache_size_gb: 50,
    }
  },
  teams+: [
    orgs.newTeam('automotive-score-technical-leads') {
      members+: [
        "FScholPer",
        "antonkri",
        "johannes-esr",
        "ltekieli",
        "markert-r",
        "qor-lb"
      ],
    },
    orgs.newTeam('cft-communication') {
      members+: [
        "FScholPer",
        "antonkri",
        "arsibo",
        "johannes-esr",
        "ltekieli",
        "markert-r",
        "qor-lb"
      ],
    },
    orgs.newTeam('cft-feo') {
      members+: [
        "AlexanderLanin",
        "FScholPer",
        "MathiasDanzeisen",
        "antonkri",
        "arsibo",
        "johannes-esr",
        "ltekieli",
        "markert-r",
        "qor-lb"
      ],
    },
    orgs.newTeam('cft-logging') {
      members+: [
        "antonkri",
        "rmaddikery",
        "hoppe-and-dreams"
      ],
    },
    orgs.newTeam('cft-orchestration') {
      members+: [
        "AlexanderLanin",
        "FScholPer",
        "MathiasDanzeisen",
        "antonkri",
        "arsibo",
        "johannes-esr",
        "ltekieli",
        "markert-r",
        "qor-lb",
        "pawelrutkaq",
        "vinodreddy-g"
      ],
    },
    orgs.newTeam('cft-persistency') {
      members+: [
        "FScholPer",
        "antonkri",
        "arsibo",
        "johannes-esr",
        "ltekieli",
        "markert-r",
        "qor-lb",
        "umaucher",
        "vinodreddy-g",
        "arkjedrz"
      ],
    },
    orgs.newTeam('community-architecture') {
      members+: [
        "FScholPer",
        "antonkri",
        "arsibo",
        "johannes-esr",
        "ltekieli",
        "markert-r",
        "qor-lb"
      ],
    },
    orgs.newTeam('community-process') {
      members+: [
        "FScholPer",
        "PandaeDo",
        "PhilipPartsch",
        "antonkri",
        "aschemmel-tech",
        "johannes-esr",
        "ltekieli",
        "markert-r",
        "masc2023",
        "pahmann",
        "qor-lb"
      ],
    },
    orgs.newTeam('community-testing') {
      members+: [
        "FScholPer",
        "antonkri",
        "johannes-esr",
        "ltekieli",
        "markert-r",
        "pahmann",
        "qor-lb"
      ],
    },
    orgs.newTeam('codeowner-lola') {
      members+: [
        "castler",
        "hoe-jo",
        "LittleHuba"
      ],
    },
    orgs.newTeam('codeowner-baselibs') {
      members+: [
        "4og",
        "antonkri"
      ],
    },
    orgs.newTeam('codeowner-baselibs_rust') {
      members+: [
      ],
    },
    orgs.newTeam('codeowner-nlohmann_json') {
      members+: [
        "4og",
      ],
    },
    orgs.newTeam('infrastructure-maintainers') {
      members+: [
        "AlexanderLanin",
        "dcalavrezo-qorix",
        "MaximilianSoerenPollak",
        "nradakovic",
      ],
    },
    orgs.newTeam('codeowner-kyron') {
      members+: [
        "pawelrutkaq",
        "vinodreddy-g",
        "qor-lb",
        "nicu1989",
      ],
    },
    orgs.newTeam('codeowner-config_management') {
      members+: [
        "antonkri",
        "4og",
        "michaelsaborov",
        "darkwisebear",
        "wei2374",
      ],
    },
    orgs.newTeam('codeowner-reference_integration') {
      members+: [
        "pawelrutkaq",
        "PiotrKorkus",
        "AlexanderLanin",
      ],
    },
  ],
  variables+: [
    orgs.newOrgVariable("ECLIPSE_PROJECT") {
      value: "automotive.score",
      visibility: "public", # all repositories have access to this variable
    },
  ],
  secrets+: [
    orgs.newOrgSecret('ECLIPSE_GITLAB_API_TOKEN') {
      value: "pass:bots/automotive.score/gitlab.eclipse.org/api-token",
    },
    orgs.newOrgSecret('SCORE_APPROVALS_PAT') {
      value: "pass:bots/automotive.score/github.com/approval-token",
    },
    orgs.newOrgSecret('SCORE_QNX_LICENSE') {
      selected_repositories+: qnx_enabled_repos,
      value: "********",
      visibility: "selected",
    },
    orgs.newOrgSecret('SCORE_QNX_PASSWORD') {
      selected_repositories+: qnx_enabled_repos,
      value: "********",
      visibility: "selected",
    },
    orgs.newOrgSecret('SCORE_QNX_USER') {
      selected_repositories+: qnx_enabled_repos,
      value: "********",
      visibility: "selected",
    },
    orgs.newOrgSecret('RENOVATE_TOKEN') {
      value: "pass:bots/automotive.score/github.com/renovate-token",
    },
    orgs.newOrgSecret('GH_PUBLISH_TOKEN') {
      selected_repositories+: [
        "eclipse-score-website"
      ],
      value: "pass:bots/automotive.score/github.com/website-token",
      visibility: "selected"
    },
    orgs.newOrgSecret('SCORE_BOT_PAT') {
      value: "pass:bots/automotive.score/github.com/token-hd6226",
    },
    orgs.newOrgSecret('SCORE_BOT_CLASSIC_PAT') {
      value: "pass:bots/automotive.score/github.com/token-hd6722",
    },
    orgs.newOrgSecret('REPO_TOKEN_USERNAME') {
      value: "vault:automotive.score/repo.eclipse.org/token-username",
    },
    orgs.newOrgSecret('REPO_TOKEN_PASSWORD') {
      value: "vault:automotive.score/repo.eclipse.org/token-password",
    },
  ],
  _repositories+:: [
    newInfrastructureTeamRepo('.github', pages = true) {
      description: "Houses the organisation README",
    },

    newInfrastructureTeamRepo('bazel_registry', subcategory = "tooling") {
      description: "Score project bazel modules registry",
      topics+: [
        "bazel",
        "registry",
        "score"
      ],
      rulesets: [
        # block all tag creations, except for infrastructure maintainers group
        block_tagging(["*"], ["@eclipse-score/infrastructure-maintainers"]),

        # overwrite default ruleset and allow admins (eclipse-score-bot) to push directly to main
        orgs.newRepoRuleset('main') {
          include_refs: ["~DEFAULT_BRANCH"],
          required_pull_request+: default_review_rule,
          bypass_actors: ["#OrganizationAdmin"],
          requires_linear_history: true,
        },
      ],
      environments: [
        orgs.newEnvironment('copilot'),
      ],
    },

    newScoreRepo('eclipse-score.github.io', pages = true, category = "website") {
      description: "The landing page website for the Score project",
      homepage: "https://eclipse-score.github.io/",
      topics+: [
        "landing-page",
        "score"
      ],
      environments: [
        orgs.newEnvironment('github-pages') {
          branch_policies+: [
            "main"
          ],
          deployment_branch_policy: "selected",
        },
      ],
    },

    newScoreRepo('eclipse-score-website', category = "website") {
      allow_rebase_merge: true,
      dependabot_security_updates_enabled: false,
      has_projects: true,
      has_wiki: true,
      rulesets: [], # reset rulesets
      allow_merge_commit: true,
      allow_update_branch: false,
      delete_branch_on_merge: false,
      dependabot_alerts_enabled: false,
      environments: [
        orgs.newEnvironment('pull-request-preview'),
      ],
    },

    newScoreRepo('eclipse-score-website-published', category = "website") {
      allow_rebase_merge: true,
      dependabot_security_updates_enabled: false,
      has_projects: true,
      has_wiki: true,
      rulesets: [], # reset rulesets
      allow_merge_commit: true,
      allow_update_branch: false,
      delete_branch_on_merge: false,
      dependabot_alerts_enabled: false,
    },

    newScoreRepo('eclipse-score-website-preview', category = "website") {
      allow_rebase_merge: true,
      dependabot_security_updates_enabled: false,
      has_projects: true,
      has_wiki: true,
      rulesets: [], # reset rulesets
      allow_merge_commit: true,
      allow_update_branch: false,
      delete_branch_on_merge: false,
      dependabot_alerts_enabled: false,
      gh_pages_build_type: "legacy",
      gh_pages_source_branch: "gh-pages-preview",
      gh_pages_source_path: "/",
      environments: [
        orgs.newEnvironment('github-pages'),
      ],
    },

    newDependableElementRepo('lifecycle') {
      aliases: [
        "inc_lifecycle",
      ],
      description: "Repository for the lifecycle feature",

      # Deviations from standard dependable element repository settings:
      template_repository: null,
      allow_update_branch: true,
      allow_rebase_merge: true,
      dependabot_security_updates_enabled: false,
      has_projects: true,
      has_wiki: true,
      code_scanning_default_setup_enabled: true,
      code_scanning_default_languages+: [
        "actions",
      ],
      branch_protection_rules: [
        main_branch_protection_rule
      ],
      rulesets: [
          orgs.newRepoRuleset('main') {
            include_refs+: [
              "refs/heads/main"
            ],
            required_pull_request+: default_review_rule,
            allows_force_pushes: false,
            requires_linear_history: true,
          },
        ],

    },

    newScoreRepo('score-crates') {
      allow_merge_commit: true,
      allow_update_branch: false,
      // TODO: re-enable after some code has been added to the repository
      // code_scanning_default_setup_enabled: true,
      // code_scanning_default_languages+: [
      //   "actions",
      // ],
      description: "Repository to provide a defined list of rust crates to be used as bzl_mods",
      gh_pages_build_type: "workflow",
      homepage: "https://eclipse-score.github.io/score-crates",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
        },
      ],
    },

    newDependableElementRepo('persistency') {
      aliases: [
        "inc_mw_per",
      ],
      description: "Repository for persistency framework",

      # Deviations from standard dependable element repository settings:
      template_repository: null,
      allow_rebase_merge: true,
      allow_update_branch: true,
      # Merge queue (instead of requires_strict_status_checks) keeps PR branches from
      # needing a manual rebase after every merge to main.
      rulesets: [
          orgs.newRepoRuleset('main') {
            include_refs+: [
              "refs/heads/main"
            ],
            required_pull_request+: default_review_rule,
            allows_force_pushes: false,
            requires_linear_history: true,
            required_merge_queue: orgs.newMergeQueue() {
              merge_method: "SQUASH",
            },
          },
        ],
    },

    newInfrastructureTeamRepo('itf', pages = true, subcategory = "integration") {
      description: "Integration Testing Framework repository",

      # Deviations from standard newScoreRepo settings:
      allow_merge_commit: true,
      allow_rebase_merge: true,
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
          required_status_checks+: {
            status_checks+: [
              "itf-build-all",
              "itf-examples-build-all",
              "itf-qnx-qemu-tests-build-all",
            ],
          },
          required_merge_queue: orgs.newMergeQueue() {
            merge_method: "MERGE",
          },
        },
      ],
      environments+: qnx_environments,
    },

    newInfrastructureTeamRepo('bazel_platforms', subcategory = "toolchains") {
      description: "Bazel platform definitions used by S-CORE modules",
    },

    newScoreRepo('process_description', pages = true, category = "general") {
      description: "Score project process description",

      // Deviations from standard newScoreRepo settings:
      has_projects: true,
      allow_merge_commit: true,
      allow_rebase_merge: true,
      allow_update_branch: false,
      environments: [
        orgs.newEnvironment('github-pages') {
          deployment_branch_policy: "all",
        },
      ],
      workflows+: {
        max_cache_size_gb: 50,
      }
    },

    newInfrastructureTeamRepo('reference_integration', true, subcategory = "integration") {
      description: "Score project integration repository",
      topics+: [
        "integration",
      ],
      environments+: qnx_environments +
        [orgs.newEnvironment('copilot')],
      # Deviations from standard dependable element repository settings:
      allow_rebase_merge: true,
      allow_update_branch: true,
      branch_protection_rules: [
        main_branch_protection_rule
      ],
      rulesets: [
          orgs.newRepoRuleset('main') {
            include_refs+: [
              "refs/heads/main"
            ],
            required_pull_request+: default_review_rule,
            allows_force_pushes: false,
            requires_linear_history: true,
          },
          orgs.newRepoRuleset('release') {
            include_refs+: [
              "refs/heads/release/**/*"
            ],
            allows_force_pushes: false,
          },
          orgs.newRepoRuleset('releases') {
            include_refs+: [
              "refs/heads/releases/**/*"
            ],
            required_pull_request+: default_review_rule,
            bypass_actors+: [
                "@eclipse-score/codeowner-reference_integration",
              ],
            allows_creations: true,
            allows_force_pushes: false,
            requires_linear_history: true,
            required_status_checks+: {
            status_checks+: [
                "check-approvals",
              ],
            },
          },
        ],
        workflows+: {
          max_cache_size_gb: 50,
        }
    },

    newInfrastructureTeamRepo('os_images', false, subcategory = "integration") {
      description: "OS Images for testing and deliveries",
    },

    newScoreRepo('score', pages = true, category = "general") {
      description: "Score project main repository",

      # Deviations from standard newScoreRepo settings:
      allow_rebase_merge: true,
      allow_merge_commit: true,
      has_projects: true,
      allow_update_branch: false,
      code_scanning_default_languages+: [
        "actions",
      ],
      code_scanning_default_setup_enabled: true,
      has_discussions: true,
      has_wiki: true,
    },

    newInfrastructureTeamRepo('tooling') {
      description: "Tooling for Eclipse S-CORE",
      gh_pages_build_type: "workflow",
      homepage: "https://eclipse-score.github.io/tooling/latest/",
      allow_rebase_merge: true,
      environments+: [
        orgs.newEnvironment('copilot'),
      ],
      allow_update_branch: true,
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
          required_status_checks+: {
            status_checks+: [
              "tooling_checks",
              "integration_tests (python_basics)",
              "integration_tests (starpls)",
              "integration_tests (cr_checker)",
              "rules_score_tests (rules_score)",
              "rules_score_tests (seooc_example)",
              "rules_score_tests (integrator_example)",
              "rules_score_tests (some_other_library_example)",
              "formatting-check",
              # copyright-check calls an external reusable workflow, hence the "caller / callee" job name
              "copyright-check / copyright-check",
            ],
          },
        },
      ],
      workflows+: {
        max_cache_size_gb: 50,
      },
    },

    newInfrastructureTeamRepo('tools') {
      description: "Home of score-tools, the new pypi based tools approach",
      environments+: [
        orgs.newEnvironment('copilot'),
        pypi_infra_env,
      ],
    },

    newInfrastructureTeamRepo('sbom-tool') {
      description: "Home of the SBOM generation tool",
      environments+: [
        orgs.newEnvironment('copilot'),
      ],
    },

    newDependableElementRepo('baselibs') {
      description: "base libraries including common functionality",

      # Deviations from standard dependable element repository settings:
      template_repository: null,
      has_projects: true,
      has_wiki: false,
      dependabot_security_updates_enabled: false,
      allow_rebase_merge: true,
      allow_merge_commit: true,
      allow_update_branch: true,
      code_scanning_default_setup_enabled: false,
      has_discussions: true,
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
          bypass_actors+: [
            "@eclipse-score/codeowner-baselibs",
          ],
          allows_force_pushes: false,
          required_status_checks+: {
            status_checks+: [
              "Restricted file changes",
              "Build and Test bl-aarch64-linux",
              "Build and Test bl-x86_64-linux",
              "Build and Test bl-aarch64-qnx / Build QNX target",
              "Build and Test bl-x86_64-qnx / Build QNX target",
            ],
          },
          required_merge_queue: orgs.newMergeQueue() {
            merge_method: "MERGE",
            status_check_timeout: 120,
          },
        },
      ],
    },

    newDependableElementRepo('communication') {
      description: "Repository for the communication module LoLa",

      # Deviations from standard dependable element repository settings:
      template_repository: null,
      gh_pages_build_type: "workflow",
      has_projects: true,
      homepage: null,
      dependabot_security_updates_enabled: false,
      allow_rebase_merge: true,
      allow_merge_commit: true,
      allow_update_branch: true,
      private_vulnerability_reporting_enabled: true,
      code_scanning_default_languages+: [
        "actions",
        "c-cpp",
        "python",
        # "rust", # not yet supported by GH API: https://docs.github.com/en/rest/code-scanning/code-scanning?apiVersion=2022-11-28#update-a-code-scanning-default-setup-configuration
      ],
      code_scanning_default_setup_enabled: false,
      has_discussions: true,
      # Merge commits must contain the PR body for checklist evidence
      merge_commit_title: "PR_TITLE",
      merge_commit_message: "PR_BODY",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
          bypass_actors+: [
            "@eclipse-score/codeowner-lola:pull_request",
          ],
          allows_force_pushes: false,
          required_status_checks+: {
            status_checks+: [
              "GCC15 / Build & Test",
              "QCC - Build & Test",
              "Address & Undefined Behavior Sanitizer / Build & Test",
              "Thread Sanitizer / Build & Test",
              "Linters / clang-tidy",
              "Linters / clippy",
              "Linters / ruff",
              "any:review-checklists",
            ],
          },
          required_merge_queue: orgs.newMergeQueue() {
            merge_method: "MERGE",
            status_check_timeout: 120,
          },
        },
        block_tagging(
          [
            "*", # block all tag creations
          ],
          [
            "@eclipse-score/codeowner-lola",
          ],
        ),
      ],
      webhooks+: [
        orgs.newRepoWebhook('https://app.readthedocs.org/api/v2/webhook/score-communication/319863/') {
          content_type: "json",
          events+: [
            "push",
            "pull_request",
            "create",
            "delete"
          ],
          secret: "pass:bots/automotive.score/readthedocs.org/webhook_secret",
        },
      ],
      secrets: [
        orgs.newRepoSecret('UBUNTU_SNAPSHOT_MIRROR_URL') {
          value: "********",
        },
      ],
    },

    newDependableElementRepo('inc_ecu_model') {
      description: "Repository for an ECU model",

      # Deviations from standard dependable element repository settings:
      template_repository: null,
      has_projects: true,
      homepage: null,
      dependabot_security_updates_enabled: false,
      allow_rebase_merge: true,
      allow_merge_commit: true,
      allow_update_branch: true,
      private_vulnerability_reporting_enabled: true,
      code_scanning_default_languages+: [
        "actions",
        "c-cpp",
        "python",
      ],
      has_discussions: true,
      # Merge commits must contain the PR body for checklist evidence
      merge_commit_title: "PR_TITLE",
      merge_commit_message: "PR_BODY",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
          bypass_actors+: [
            "@eclipse-score/codeowner-lola:pull_request",
          ],
          allows_force_pushes: false,
          required_status_checks+: {
            status_checks+: [
              "Build & Test",
              "copyright",
              "ruff",
            ],
          },
          required_merge_queue: orgs.newMergeQueue() {
            merge_method: "MERGE",
            status_check_timeout: 120,
          },
        },
        block_tagging(
          [
            "*", # block all tag creations
          ],
          [
            "@eclipse-score/codeowner-lola",
          ],
        ),
      ],
    },

    newInfrastructureTeamRepo('rules_imagefs', subcategory = "integration") {
      description: "Repository for Image FileSystem Bazel rules and toolchains definitions",
      environments+: qnx_environments,
    },

    newInfrastructureTeamRepo('bazel_cpp_toolchains', subcategory = "toolchains") {
      description: "Bazel C/C++ toolchain configuration repository",
      environments+: qnx_environments,
      workflows+: {
        max_cache_size_gb: 50,
      }
    },

    newInfrastructureTeamRepo('toolchains_gcc_packages', subcategory = "toolchains") {
      description: "Bazel toolchains for GNU GCC",
    },

    newInfrastructureTeamRepo('toolchains_rust', subcategory = "toolchains") {
      description: "Rust toolchains",
    },

    newInfrastructureTeamRepo('ferrocene_toolchain_builder', subcategory = "toolchains") {
      description: "Builder for Ferrocene artifacts",
      environments+: qnx_environments,
    },

    newInfrastructureTeamRepo('module_template', pages = true) {
      description: "C++ & Rust Bazel Template Repository",
      is_template: true,
      workflows+: {
        max_cache_size_gb: 50,
      }
    },

    newInfrastructureTeamRepo('cicd-actions', subcategory = "automation") {
      description: "Reusable GitHub Actions for CI/CD automation",
    },

    newInfrastructureTeamRepo('cicd-workflows', subcategory = "automation") {
      description: "Reusable GitHub Workflows for CI/CD automation",
    },

    newInfrastructureTeamRepo('docs-as-code', pages = true, subcategory = "tooling") {
      description: "Docs-as-code tooling for Eclipse S-CORE",

      environments+: [
        orgs.newEnvironment('copilot'),
      ],
      workflows+: {
        max_cache_size_gb: 50,
      }
    },

    newInfrastructureTeamRepo('coverage_tool', pages = true, subcategory = "tooling") {
      description: "LLVM source-based code coverage pipeline for Eclipse S-CORE (Bazel module score_coverage)",
      topics+: [
        "bazel",
        "code-coverage",
        "llvm-cov",
      ],
      allow_rebase_merge: true,
      allow_update_branch: true,
      environments+: [
        orgs.newEnvironment('copilot'),
      ],
      # Required status checks are added once the repository has its CI workflows.
    },

    newDependableElementRepo('orchestrator') {
      description: "Orchestration framework & Safe async runtime for Rust",

      # Deviations from standard dependable element repository settings:
      allow_rebase_merge: true,
      dependabot_security_updates_enabled: false,
      has_projects: true,
      has_wiki: true,
      template_repository: null,
      allow_update_branch: true,
      code_scanning_default_setup_enabled: true,
      code_scanning_default_languages+: [
        "actions",
        "python",
      ],
      branch_protection_rules: [
        main_branch_protection_rule
      ],
      rulesets: [
          orgs.newRepoRuleset('main') {
            include_refs+: [
              "refs/heads/main"
            ],
            required_pull_request+: default_review_rule,
            allows_force_pushes: false,
            requires_linear_history: true,
          },
        ],
    },

    newScoreRepo("nlohmann_json", true) {
        aliases: [
          "inc_nlohmann_json",
        ],
        description: "Nlohmann JSON Library",
        forked_repository: "nlohmann/json",
        default_branch: "main",
        allow_rebase_merge: true,
        allow_merge_commit: true,
        has_discussions: true,
        has_wiki: true,
        dependabot_alerts_enabled: true,
        dependabot_security_updates_enabled: false,
        rulesets: [
          orgs.newRepoRuleset('main') {
            include_refs+: [
              "refs/heads/main"
            ],
            required_pull_request+: default_review_rule,
            allows_force_pushes: false,
            requires_linear_history: true,
          },
        ],
        workflows+: {
          max_cache_size_gb: 50,
        }
    },

    newInfrastructureTeamRepo('score_rust_policies', subcategory = "toolchains") {
      description: "Centralized Rust linting and formatting policies for S-CORE, including safety-critical guidelines.",
      gh_pages_build_type: "workflow",
      homepage: "https://eclipse-score.github.io/score_rust_policies",
      topics+: [
        "rust",
        "linting",
        "formatting",
        "score",
        "policy",
      ],
    },

    newInfrastructureTeamRepo('score_cpp_policies', subcategory = "toolchains") {
      description: "Centralized C++ quality tool policies for S-CORE, including sanitizer configurations and safety-critical guidelines.",
      gh_pages_build_type: "workflow",
      homepage: "https://eclipse-score.github.io/score_cpp_policies",
      topics+: [
        "cpp",
        "sanitizers",
        "clang-tidy",
        "policy",
        "score",
      ],
    },

    newInfrastructureTeamRepo('bazel_registry_ui', pages = true, subcategory = "tooling") {
      description: "House the ui for bazel_registry in Score",

      # It's a fork. We don't want to change the entire codebase.
      code_scanning_default_setup_enabled: false,
      dependabot_security_updates_enabled: false,

      rulesets: [], # reset rulesets
      gh_pages_build_type: "legacy",
      gh_pages_source_branch: "gh-pages",
      gh_pages_source_path: "/",
      forked_repository:"bazel-contrib/bcr-ui",
    },

    newInfrastructureTeamRepo("rules_rust", subcategory = "toolchains") {
      description: "S-CORE fork of bazelbuild/rules_rust",
      forked_repository: "bazelbuild/rules_rust",
      default_branch: "score_main",

      # It's a fork. We don't want to change the entire codebase.
      code_scanning_default_setup_enabled: false,
      dependabot_security_updates_enabled: false,

      rulesets+: [
        orgs.newRepoRuleset('score_main') {
          include_refs+: [
            "refs/heads/score_main"
          ],
          required_pull_request+: default_review_rule,
        },
      ],
    },

    newInfrastructureTeamRepo('more-disk-space', subcategory = "automation") {
      description: "GitHub Action to make more disk space available in Ubuntu based GitHub Actions runners",
    },

    newInfrastructureTeamRepo('apt-install', subcategory = "automation") {
      description: "GitHub Action to execute apt-install in a clever way",
    },

    newInfrastructureTeamRepo('devcontainer', subcategory = "tooling") {
      description: "Common DevContainer for Eclipse S-CORE",
      delete_branch_on_merge: true,
      squash_merge_commit_title: "PR_TITLE",
      squash_merge_commit_message: "PR_BODY",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "~DEFAULT_BRANCH"
          ],
          required_pull_request+: default_review_rule,
          required_status_checks+: {
            status_checks+: [
              "build/overall-result",
            ],
          },
          required_merge_queue: orgs.newMergeQueue() {
            merge_method: "SQUASH",
          },
        },
      ],
    },

    newInfrastructureTeamRepo('dash-license-scan', subcategory = "tooling") {
      description: "pipx/uvx wrapper for the dash-licenses tool",
      environments+: [
        pypi_infra_env,
      ],
    },

    newInfrastructureTeamRepo('infrastructure', true) {
      description: "All general information related to the development and integration infrastructure",
    },

    newInfrastructureTeamRepo('testing_tools', subcategory = "integration") {
      description: "Repository for testing utilities",
    },

    newDependableElementRepo('feo') {
      description: "Repository for the Fixed Order Execution (FEO) framework",
    },

    newDependableElementRepo('inc_daal', subcategory = "incubation") {
      description: "Incubation repository for DAAL module",
    },

    newInfrastructureTeamRepo('os_autosd') {
      aliases: [
        "inc_os_autosd",
      ],
      description: 'Repository for the AutoSD Platform and associated Tooling',
      gh_pages_build_type: "workflow",
      template_repository: "eclipse-score/module_template",
      homepage: "https://eclipse-score.github.io/os_autosd",
    },

    newScoreRepo('bazel-tools-python') {
      description: "Repository for python static code checker",
    }
    + { template_repository: "eclipse-score/module_template",
        environments: [
        orgs.newEnvironment('github-pages') {
          branch_policies+: [
            "main"
          ],
          deployment_branch_policy: "selected",
        },
      ],
    },

    newInfrastructureTeamRepo('bazel-tools-cc', subcategory = "toolchains") {
      description: "Repository for clang-tidy based static code checker",
    }
    + {
      template_repository: "eclipse-score/module_template" ,
      environments: [
        orgs.newEnvironment('github-pages') {
          branch_policies+: [
            "main"
          ],
          deployment_branch_policy: "selected",
        },
      ],
    },

    newScoreRepo('mcp-servers') {
      description: "Repository for MCP servers",
    },

    newDependableElementRepo('logging') {
      description: "Repository for logging daemon",

      # Deviations from standard dependable element repository settings:
      allow_rebase_merge: true,
      allow_update_branch: true,
      branch_protection_rules: [
        main_branch_protection_rule
      ],
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
          bypass_actors+: [
            "@eclipse-score/cft-logging",
          ],
          allows_force_pushes: false,
          requires_linear_history: true,
        },
      ],
    },

    newDependableElementRepo('scrample') {
      description: "Repository for example component",
    },

    newScoreRepo('dev_playground') {
      description: "Repository for developer tools and playground",
    },

    newDependableElementRepo('inc_someip_gateway', subcategory = "incubation") {
      description: "Incubation repository for SOME/IP gateway feature",
      delete_branch_on_merge: true,
      squash_merge_commit_title: "PR_TITLE",
      squash_merge_commit_message: "PR_BODY",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "~DEFAULT_BRANCH"
          ],
          required_pull_request+: default_review_rule,
          required_status_checks+: {
            status_checks+: [
              "ci/can_merge",
              "ci_pull_request_target/can_merge",
            ],
          },
          required_merge_queue: orgs.newMergeQueue() {
            merge_method: "SQUASH",
          },
        },
      ],
    },

    newDependableElementRepo('inc_diagnostics', subcategory = "incubation") {
      description: "Incubation repository for diagnostics feature",
    },

    newDependableElementRepo('inc_security_crypto') {
      description: "Incubation repository for Security & Cryptography feature",
    },

    newDependableElementRepo('kyron') {
      description: "Safe async runtime for Rust",

      # Deviations from standard dependable element repository settings:
      allow_rebase_merge: true,
      allow_update_branch: true,
      branch_protection_rules: [
        main_branch_protection_rule
      ],
      rulesets: [
          orgs.newRepoRuleset('main') {
            include_refs+: [
              "refs/heads/main"
            ],
            required_pull_request+: default_review_rule,
            allows_force_pushes: false,
            requires_linear_history: true,
          },
        ],
    },

    newDependableElementRepo('time') {
      aliases: [
        "inc_time",
      ],
      description: "Time synchronization module",

      # Deviations from standard dependable element repository settings:
      allow_merge_commit: true,
      allow_update_branch: true,
      allow_rebase_merge: true,

      branch_protection_rules: [
        main_branch_protection_rule
      ],
      rulesets: [
          orgs.newRepoRuleset('main') {
            include_refs+: [
              "refs/heads/main"
            ],
            required_pull_request+: default_review_rule,
            allows_force_pushes: false,
            requires_linear_history: true,
          },
      ],
    },

    newDependableElementRepo('config_management') {
      description: "Repository for config management",

      # Deviations from standard dependable element repository settings:
      allow_rebase_merge: true,
      allow_update_branch: false,
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
          bypass_actors+: [
            "@eclipse-score/codeowner-config_management",
          ],
          allows_force_pushes: false,
          requires_linear_history: true,
        },
      ],
    },

    newInfrastructureTeamRepo('qnx_unit_tests', subcategory = "testing") {
      description: "Infrastructure for running unit tests in QNX VMs",

      # Deviations from standard newInfrastructureTeamRepo settings:
      allow_merge_commit: true,
      allow_rebase_merge: true,
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
          required_status_checks+: {
            status_checks+: [
              "qnx-ut-build-all",
              "qnx-ut-examples-build-all",
            ],
          },
          required_merge_queue: orgs.newMergeQueue() {
            merge_method: "MERGE",
          },
        },
      ],
      environments+: qnx_environments,
    },


    # ---- Archived repositories ----

    newInfrastructureTeamRepo('toolchains_gcc', subcategory = "toolchains") {
      archived: true,
      description: "Bazel toolchains for GNU GCC",
    },

    newInfrastructureTeamRepo('toolchains_qnx', subcategory = "toolchains") {
      archived: true,
      description: "Bazel toolchains for QNX",

      # Deviations from standard newScoreRepo settings:
      environments+: qnx_environments,
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
          required_status_checks+: {
            status_checks+: [
              "toolchains-qnx-build-all",
            ],
          },
          required_merge_queue: orgs.newMergeQueue() {
            merge_method: "MERGE",
          },
        },
      ],
    },

    orgs.newRepo('inc_feo') {
      allow_merge_commit: true,
      allow_update_branch: false,
      archived: true,
      code_scanning_default_setup_enabled: true,
      code_scanning_default_languages+: [
        "actions",
      ],
      description: "Incubation repository for the fixed execution order framework",
      homepage: "https://eclipse-score.github.io/inc_feo",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
        },
      ],
    },

    orgs.newRepo('inc_mw_com') {
      allow_merge_commit: true,
      allow_update_branch: false,
      archived: true,
      code_scanning_default_languages+: [
        "python"
      ],
      code_scanning_default_setup_enabled: true,
      description: "Incubation repository for interprocess communication framework",
      homepage: "https://eclipse-score.github.io/inc_mw_com",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
        },
      ],
    },

    orgs.newRepo('inc_mw_log') {
      allow_merge_commit: true,
      allow_update_branch: false,
      archived: true,
      code_scanning_default_setup_enabled: true,
      description: "Incubation repository for logging framework",
      homepage: "https://eclipse-score.github.io/inc_mw_log",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
        },
      ],
    },

    orgs.newRepo('inc_process_test_management') {
      allow_merge_commit: true,
      allow_update_branch: false,
      archived: true,
      code_scanning_default_setup_enabled: true,
      description: "Incubation repository for Process - Sphinx-Test management",
      homepage: "https://eclipse-score.github.io/inc_process_test_management",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: {
            dismisses_stale_reviews: true,
            required_approving_review_count: 1,
            requires_code_owner_review: false,
          },
        },
      ],
    },

    orgs.newRepo('inc_process_variant_management') {
      allow_merge_commit: true,
      allow_update_branch: false,
      archived: true,
      code_scanning_default_setup_enabled: true,
      description: "Incubation repository for Process - Sphinx-Variant management",
      homepage: "https://eclipse-score.github.io/inc_process_variant_management",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: {
            dismisses_stale_reviews: true,
            required_approving_review_count: 1,
            requires_code_owner_review: false,
          },
        },
      ],
      environments: [
        orgs.newEnvironment('github-pages'),
      ],
    },

    orgs.newRepo('operating_system') {
      allow_merge_commit: true,
      allow_update_branch: false,
      code_scanning_default_setup_enabled: true,
      archived: true,
      description: "Repository for the module operating system",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
        },
      ],
    },

    orgs.newRepo('examples') {
      allow_merge_commit: true,
      allow_update_branch: false,
      archived: true,
      code_scanning_default_setup_enabled: true,
      description: "Hosts templates and examples for score tools and workflows",
      homepage: "https://eclipse-score.github.io/examples",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
        },
      ],
    },

    orgs.newRepo('inc_score_codegen') {
      allow_merge_commit: true,
      allow_update_branch: false,
      archived: true,
      // code must be present to enable code scanning
      // code_scanning_default_languages+: [
      //   "python"
      // ],
      code_scanning_default_setup_enabled: true,
      description: "Incubation repository for DSL/code-gen specific to score project",
      homepage: "https://eclipse-score.github.io/inc_score_codegen",
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          required_pull_request+: default_review_rule,
        },
      ],
    },

    newDependableElementRepo('baselibs_rust') {
      description: "Repository for the Rust baselibs",

      # Deviations from standard dependable element repository settings:
      allow_update_branch: true,
      archived: true,
      allow_rebase_merge: true,
      branch_protection_rules: [
        main_branch_protection_rule
      ],
      // Override the rulesets
      rulesets: [
        orgs.newRepoRuleset('main') {
          include_refs+: [
            "refs/heads/main"
          ],
          bypass_actors+: [
            "@eclipse-score/codeowner-baselibs_rust",
          ],
          required_pull_request+: default_review_rule,
          allows_force_pushes: false,
          requires_linear_history: true,
        },
      ],
    },

    newDependableElementRepo('inc_json') {
      archived: true,
      description: "Incubation repository for JSON module",
    },

    newDependableElementRepo('inc_config_management') {
      archived: true,
      description: "Incubation repository for config management",
    },

    newDependableElementRepo('inc_abi_compatible_datatypes') {
      archived: true,
      description: "Incubation repository for ABI compatible data types feature",
    },

    newDependableElementRepo('inc_ai_platform') {
      archived: true,
      description: "Incubation repository for AI platform feature",
    },

    newDependableElementRepo('inc_gen_ai') {
      archived: true,
      description: "Incubation repository for Generative AI feature",
    },
  ],
}
