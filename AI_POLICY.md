# ArchivesSpace AI Contribution Policy

# **Purpose and scope**

This AI Contribution Policy serves to augment our existing guidelines ([Code of Conduct.md](https://github.com/archivesspace/archivesspace/blob/master/CODE_OF_CONDUCT.md), [CONTRIBUTING.md](https://github.com/archivesspace/archivesspace/blob/master/CONTRIBUTING.md), [SECURITY.md](https://github.com/archivesspace/archivesspace/blob/master/SECURITY.md), [Contributor License Agreements](https://github.com/archivesspace/archivesspace/tree/master/contribution_files), and Code Review Guidelines). It does not supersede our current practices; rather, it provides specific guardrails for the use of Large Language Models (LLMs) and generative AI tools in the development process.

This is an evolving policy and may be updated as technologies and practices mature.

ArchivesSpace maintainers reserve the right to refuse any contribution they consider low-effort or of low value, without providing a detailed technical critique.

For the purposes of this statement, “Contribution” is understood to mean any of the following:

* Software code
* Code reviews
* Documentation
* Training Materials
* UI text translations
* Issue content (on Jira or github issues)
* Any other content

You MAY use LLMs and generative AI tools for any of the contributions listed above, as long as you adhere to the following principles of accountability and transparency:

# **Accountability**

You MUST take the responsibility for your contribution. The human contributor:

1. Must fully understand and be able to explain every bit of the submission.
2. Remains personally responsible and accountable for the contribution, including any code produced with the assistance of AI tools or other collaborators.
3. Vouches for the quality of the submission.
4. MAY NOT use AI tools as the sole or final arbiter when performing a code review for another person’s contribution.
   1. An AI agent cannot sign-off on pull requests and automated comments from AI agents may be ignored.
   2. This does not prohibit the use of automated tooling for objective technical validation, such as CI/CD pipelines, automated testing, or spam filtering.   However, the final accountability for accepting a contribution, even if implemented by an automated system, always rests with the human contributor who authorizes the action.
5. MUST NOT give AI tools passwords, API keys, or other credentials, or real data from an ArchivesSpace instance you manage, such as restricted records or personal information.
6. All contributions, whether from a human author or assisted by large language models (LLMs) or other generative AI tools, must meet the project’s standards for inclusion.

# **Transparency**

If AI was used to generate a significant portion of your contribution you MUST disclose this. Routine use of assistive tools for correcting grammar and spelling, or for clarifying language, does not require disclosure.

## Code Contributions

* Code comments:
  * LLMs tend to produce verbose in-line comments. Make sure every comment, including AI-generated ones:
    * is concise
    * does not try to make up for unclear code; good naming cannot be replaced by comment verbosity

  * Examples of comments worth adding include:
    * explaining a design choice, with a ticket reference for more context
    * a TODO, which should always refer to a specific ticket

* Commit Messages could include one or more of the following trailers:
  * Assisted-by: \<Name of AI agent\> \[Model Used\]
  * Generated-by: \<Name of AI agent\> \[Model Used\]
  * Co-authored-by: \<Name of AI agent\> \[Model Used\]
  * Signed-off-by: \<Human Responsible\>

* Pull Requests (PRs) descriptions are encouraged to:
  * Be concise
  * Be human-owned
  * Assert that any AI-generated or assisted code was reviewed for security, efficiency and accuracy, and that it adheres to the project’s coding standards.
    Example PR template
    \#\# 🤖 AI Usage Disclosure

    \- \[ \] This PR contains AI-generated code or content. If checked, please specify which parts were generated and how they were validated: \[Briefly describe here\]

    \#\# 🛡️ AI Validation Check

    \- \[ \] I have reviewed and verified all AI-generated code for security, efficiency, and accuracy.
    \- \[ \] I have ensured the AI-generated code adheres to the project's coding standards.

## Code Reviews

The code reviewer MUST take accountability for the review. Every review comment must be one you understand and can explain; do not post an AI tool's findings you have not checked yourself.

The review summary MUST list all AI tools used, along with a description of their role in the code review.


## Large scale initiatives

The policy does not cover large scale initiatives which may significantly change the ways the project operates or lead to exponential growth in contributions in some parts of the project. Such initiatives need to be discussed separately with the ArchivesSpace Program Team.

# **Copyright & Legal**

The copyright and licensing terms in [CONTRIBUTING.md](https://github.com/archivesspace/archivesspace/blob/master/CONTRIBUTING.md) apply to all contributions, including AI-assisted ones. When you use AI tools, take reasonable care that the output can be contributed under the ArchivesSpace license:

* Use AI tools whose terms of service allow you to contribute their output under the ArchivesSpace license.
* Watch for output that looks copied from an existing project, such as long blocks of familiar code, license headers, or distinctive comments. If you find it, remove it, or credit it if its license is compatible.
* If your tool has a setting that blocks or flags output matching public code, turn it on.
* Disclose AI use as described under Transparency, so maintainers can act if a licensing question comes up later.
* If you have reason to believe AI output reproduces code you are not able to license to ArchivesSpace, do not submit it.

# **Enforcement**

Cases of repeated violations of these (or any of our other contributor guidelines) could result in a ban from our repositories.

Concerns about possible policy violations should be reported to  [ArchivesSpaceHome@lyrasis.org](mailto:ArchivesSpaceHome@lyrasis.org).

# **Acknowledgements**

This policy draws upon and was informed by
[https://github.com/mastodon/.github/blob/main/AI\_POLICY.md](https://github.com/mastodon/.github/blob/main/AI_POLICY.md)
[https://docs.fedoraproject.org/en-US/council/policy/ai-contribution-policy/](https://docs.fedoraproject.org/en-US/council/policy/ai-contribution-policy/)
