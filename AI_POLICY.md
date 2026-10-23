# ArchivesSpace AI Contribution Policy

# **Values Statement**

\[ A statement of program values and general approach to AI\]

This AI Contribution Policy serves to augment our existing guidelines ([Code of Conduct.md](https://github.com/archivesspace/archivesspace/blob/master/CODE_OF_CONDUCT.md), [CONTRIBUTING.md](https://github.com/archivesspace/archivesspace/blob/master/CONTRIBUTING.md), [SECURITY.md](https://github.com/archivesspace/archivesspace/blob/master/SECURITY.md), and Code Review Guidelines). It does not supersede our current practices; rather, it provides specific guardrails for the use of Large Language Models (LLMs) and generative AI tools in the development process.

This is an evolving policy and may be updated as technologies and practices mature.

For the purposes of this statement, “Contribution” is understood to mean any of the following:

* Software code
* Code reviews
* Documentation
* Training Materials
* UI text translations

You MAY use LLMs and generative AI tools when contributing to ArchivesSpace as long as you adhere to the following principles:

# **Accountability**

You MUST take the responsibility for your contribution. The human contributor:

1. Must fully understand and be able to explain every bit of the submission.
2. Is the sole party responsible for the contribution.
3. Vouches for the quality and license compliance of the submission.
4. All contributions, whether from a human author or assisted by large language models (LLMs) or other generative AI tools, must meet the project’s standards for inclusion.
5. MAY NOT use AI tools as the sole or final arbiter when performing a code review for another person’s contribution.
   1. An AI agent cannot sign-off on pull requests and automated comments from AI agents may be ignored.
   2. This does not prohibit the use of automated tooling for objective technical validation, such as CI/CD pipelines, automated testing, or spam filtering.   However, the final accountability for accepting a contribution, even if implemented by an automated system, always rests with the human contributor who authorizes the action.

# **Transparency**

If AI was used to generate a significant portion of your contribution you MUST disclose this. Routine use of assistive tools for correcting grammar and spelling, or for clarifying language, does not require disclosure.

## Code Contributions

* In-line code comments MUST….
  * Do not duplicate code in comments. Adding comments should not replace our efforts for readability.
  * Let’s figure out what would belong to agent files and what to code comments.
  * Add a comment to:
    * Defend a code design choice \- add a ticket reference to give more context
    * Add a TODO \- which should always refer to specific ticket(s)
* Commit Messages could include one or more of the following trailers:
  * Assisted-by: \<Name of AI agent\> \[Model Used\]\<-- probably most preferable?
  * Generated-by: \<Name of AI agent\> \[Model Used\]
  * Co-authored-by: \<Name of AI agent\> \[Model Used\]
  * Signed-off-by: \<Human Responsible\>
* Pull Requests (PRs) descriptions are encouraged to:
  * Be human-owned
  * Specify whether the PR includes AI-generated or AI-assisted content and if so, include a description of the content that was generated or assisted by AI.
  * Assert that any AI-generated or assisted code was reviewed for security, efficiency and accuracy, that it complies with all licensing and legal requirements and that it adheres to the project’s coding standards.
    Example PR template
    \#\# 🤖 AI Usage Disclosure

    \-\[ \] This PR does not use AI-generated content.
    \-\[ \] This PR contains AI-generated code or content. If checked, please specify which parts were generated and how they were validated: \[Briefly describe here\]

    \#\# 🛡️ AI Validation Check

    \- \[ \] I have reviewed and verified all AI-generated code for security, efficiency, and accuracy.
    \- \[ \] I have verified that the code complies with all licensing and legal policies.
    \- \[ \] I have ensured the AI-generated code adheres to the project's coding standards.

## Code Reviews

The code reviewer MUST take accountability for the review.

Review comments MUST list all AI tools used, along with a description of their role in the code review.

## Documentation

If AI tools were used to \[assist, generate any portion of\] a documentation contribution the human author SHOULD credit AI.

\[ Program-specific requirements here if applicable \]

## All Other Contributions

Disclose use of AI in whatever manner is most appropriate to the contribution type, including the nature of the use and how it impacted the final outcome.

## Large scale initiatives

The policy does not cover the large scale initiatives which may significantly change the ways the project operates or lead to exponential growth in contributions in some parts of the project. Such initiatives need to be discussed separately with the Fedora Council.

# **Copyright & Legal**

By submitting a contribution to ArchivesSpace, you represent and warrant that:

* You have the legal right to submit the contribution under the project's (or specific repository) licence.
* The contribution does not violate the intellectual property rights of any third party.
* If AI was used, the resulting code does not violate the terms of service of the AI provider and does not include "regurgitated" code from libraries with incompatible licences to the repository you’re submitting it to.
* If you cannot guarantee the provenance and legal safety of the AI-generated code, do not submit it.

# **Prohibited Uses**

The following are expressly prohibited:

* Contributions initiated by Autonomous AI agents
* Automated PR Descriptions
* Submitting issues or PRs for features or bug fixes that don't exist, based on AI hallucinations about the project's capabilities.
* No sharing of sensitive data or api keys

# **Recommended AI Tools**

\[ Program-specific list, if applicable \]

# **Enforcement**

ArchivesSpace maintainers reserve the right to refuse any contribution that appears to be a low-effort AI contribution, without providing a detailed technical critique.

Cases of repeated violations of these (or any of our other contributor guidelines) could result in a ban from our repositories.

Concerns about possible policy violations should be reported to  [ArchivesSpaceHome@lyrasis.org](mailto:ArchivesSpaceHome@lyrasis.org).

# **Acknowledgements**

This policy draws upon and was informed by
[https://github.com/mastodon/.github/blob/main/AI\_POLICY.md](https://github.com/mastodon/.github/blob/main/AI_POLICY.md)
[https://docs.fedoraproject.org/en-US/council/policy/ai-contribution-policy/](https://docs.fedoraproject.org/en-US/council/policy/ai-contribution-policy/)
