


<!DOCTYPE html>
<html lang="en" class="">
  <head prefix="og: http://ogp.me/ns# fb: http://ogp.me/ns/fb# object: http://ogp.me/ns/object# article: http://ogp.me/ns/article# profile: http://ogp.me/ns/profile#">
    <meta charset='utf-8'>
    <meta http-equiv="X-UA-Compatible" content="IE=edge">
    <meta http-equiv="Content-Language" content="en">
    <meta name="viewport" content="width=1020">
    
    
    <title>archivesspace/README_JASMINE.md at js-unit-testing · quoideneuf/archivesspace · GitHub</title>
    <link rel="search" type="application/opensearchdescription+xml" href="/opensearch.xml" title="GitHub">
    <link rel="fluid-icon" href="https://github.com/fluidicon.png" title="GitHub">
    <link rel="apple-touch-icon" sizes="57x57" href="/apple-touch-icon-114.png">
    <link rel="apple-touch-icon" sizes="114x114" href="/apple-touch-icon-114.png">
    <link rel="apple-touch-icon" sizes="72x72" href="/apple-touch-icon-144.png">
    <link rel="apple-touch-icon" sizes="144x144" href="/apple-touch-icon-144.png">
    <meta property="fb:app_id" content="1401488693436528">

      <meta content="@github" name="twitter:site" /><meta content="summary" name="twitter:card" /><meta content="quoideneuf/archivesspace" name="twitter:title" /><meta content="archivesspace - The ArchivesSpace archives management tool" name="twitter:description" /><meta content="https://avatars0.githubusercontent.com/u/1626547?v=3&amp;s=400" name="twitter:image:src" />
      <meta content="GitHub" property="og:site_name" /><meta content="object" property="og:type" /><meta content="https://avatars0.githubusercontent.com/u/1626547?v=3&amp;s=400" property="og:image" /><meta content="quoideneuf/archivesspace" property="og:title" /><meta content="https://github.com/quoideneuf/archivesspace" property="og:url" /><meta content="archivesspace - The ArchivesSpace archives management tool" property="og:description" />
      <meta name="browser-stats-url" content="https://api.github.com/_private/browser/stats">
    <meta name="browser-errors-url" content="https://api.github.com/_private/browser/errors">
    <link rel="assets" href="https://assets-cdn.github.com/">
    
    <meta name="pjax-timeout" content="1000">
    

    <meta name="msapplication-TileImage" content="/windows-tile.png">
    <meta name="msapplication-TileColor" content="#ffffff">
    <meta name="selected-link" value="repo_source" data-pjax-transient>

    <meta name="google-site-verification" content="KT5gs8h0wvaagLKAVWq8bbeNwnZZK1r1XQysX3xurLU">
    <meta name="google-analytics" content="UA-3769691-2">

<meta content="collector.githubapp.com" name="octolytics-host" /><meta content="github" name="octolytics-app-id" /><meta content="6C1B1673:09B2:1E169CC9:564111ED" name="octolytics-dimension-request_id" />

<meta content="Rails, view, blob#show" data-pjax-transient="true" name="analytics-event" />


  <meta class="js-ga-set" name="dimension1" content="Logged Out">
    <meta class="js-ga-set" name="dimension4" content="Current repo nav">




    <meta name="is-dotcom" content="true">
        <meta name="hostname" content="github.com">
    <meta name="user-login" content="">

      <link rel="mask-icon" href="https://assets-cdn.github.com/pinned-octocat.svg" color="#4078c0">
      <link rel="icon" type="image/x-icon" href="https://assets-cdn.github.com/favicon.ico">

    <meta content="f3eca5325eeea76f7305e4f40357a31fcf5ee7b2" name="form-nonce" />

    <link crossorigin="anonymous" href="https://assets-cdn.github.com/assets/github-e1c13e7309dc7f723b21b2afc0a6ee6a9e8e5978fe25dccb3251d923cab472df.css" media="all" rel="stylesheet" />
    <link crossorigin="anonymous" href="https://assets-cdn.github.com/assets/github2-8660e134f8078fe75046e2c8cf09a2fd65d94446a9c3d11ecf672cb4c5842b6a.css" media="all" rel="stylesheet" />
    
    
    


    <meta http-equiv="x-pjax-version" content="bfd96d846aa5a35d072709105fddd787">

      
  <meta name="description" content="archivesspace - The ArchivesSpace archives management tool">
  <meta name="go-import" content="github.com/quoideneuf/archivesspace git https://github.com/quoideneuf/archivesspace.git">

  <meta content="1626547" name="octolytics-dimension-user_id" /><meta content="quoideneuf" name="octolytics-dimension-user_login" /><meta content="11981470" name="octolytics-dimension-repository_id" /><meta content="quoideneuf/archivesspace" name="octolytics-dimension-repository_nwo" /><meta content="true" name="octolytics-dimension-repository_public" /><meta content="true" name="octolytics-dimension-repository_is_fork" /><meta content="4989765" name="octolytics-dimension-repository_parent_id" /><meta content="archivesspace/archivesspace" name="octolytics-dimension-repository_parent_nwo" /><meta content="4965957" name="octolytics-dimension-repository_network_root_id" /><meta content="hudmol/archivesspace" name="octolytics-dimension-repository_network_root_nwo" />
  <link href="https://github.com/quoideneuf/archivesspace/commits/js-unit-testing.atom" rel="alternate" title="Recent Commits to archivesspace:js-unit-testing" type="application/atom+xml">

  </head>


  <body class="logged_out   env-production  vis-public fork page-blob">
    <a href="#start-of-content" tabindex="1" class="accessibility-aid js-skip-to-content">Skip to content</a>

    
    
    



      
      <div class="header header-logged-out" role="banner">
  <div class="container clearfix">

    <a class="header-logo-wordmark" href="https://github.com/" data-ga-click="(Logged out) Header, go to homepage, icon:logo-wordmark">
      <span class="mega-octicon octicon-logo-github"></span>
    </a>

    <div class="header-actions" role="navigation">
        <a class="btn btn-primary" href="/join" data-ga-click="(Logged out) Header, clicked Sign up, text:sign-up">Sign up</a>
      <a class="btn" href="/login?return_to=%2Fquoideneuf%2Farchivesspace%2Fblob%2Fjs-unit-testing%2Ffrontend%2FREADME_JASMINE.md" data-ga-click="(Logged out) Header, clicked Sign in, text:sign-in">Sign in</a>
    </div>

    <div class="site-search repo-scope js-site-search" role="search">
      <!-- </textarea> --><!-- '"` --><form accept-charset="UTF-8" action="/quoideneuf/archivesspace/search" class="js-site-search-form" data-global-search-url="/search" data-repo-search-url="/quoideneuf/archivesspace/search" method="get"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div>
  <label class="js-chromeless-input-container form-control">
    <div class="scope-badge">This repository</div>
    <input type="text"
      class="js-site-search-focus js-site-search-field is-clearable chromeless-input"
      data-hotkey="s"
      name="q"
      placeholder="Search"
      aria-label="Search this repository"
      data-global-scope-placeholder="Search GitHub"
      data-repo-scope-placeholder="Search"
      tabindex="1"
      autocapitalize="off">
  </label>
</form>
    </div>

      <ul class="header-nav left" role="navigation">
          <li class="header-nav-item">
            <a class="header-nav-link" href="/explore" data-ga-click="(Logged out) Header, go to explore, text:explore">Explore</a>
          </li>
          <li class="header-nav-item">
            <a class="header-nav-link" href="/features" data-ga-click="(Logged out) Header, go to features, text:features">Features</a>
          </li>
          <li class="header-nav-item">
            <a class="header-nav-link" href="https://enterprise.github.com/" data-ga-click="(Logged out) Header, go to enterprise, text:enterprise">Enterprise</a>
          </li>
          <li class="header-nav-item">
            <a class="header-nav-link" href="/pricing" data-ga-click="(Logged out) Header, go to pricing, text:pricing">Pricing</a>
          </li>
      </ul>

  </div>
</div>



    <div id="start-of-content" class="accessibility-aid"></div>

    <div id="js-flash-container">
</div>


    <div role="main" class="main-content">
        <div itemscope itemtype="http://schema.org/WebPage">
    <div class="pagehead repohead instapaper_ignore readability-menu">

      <div class="container">

        <div class="clearfix">
          

<ul class="pagehead-actions">

  <li>
      <a href="/login?return_to=%2Fquoideneuf%2Farchivesspace"
    class="btn btn-sm btn-with-count tooltipped tooltipped-n"
    aria-label="You must be signed in to watch a repository" rel="nofollow">
    <span class="octicon octicon-eye"></span>
    Watch
  </a>
  <a class="social-count" href="/quoideneuf/archivesspace/watchers">
    1
  </a>

  </li>

  <li>
      <a href="/login?return_to=%2Fquoideneuf%2Farchivesspace"
    class="btn btn-sm btn-with-count tooltipped tooltipped-n"
    aria-label="You must be signed in to star a repository" rel="nofollow">
    <span class="octicon octicon-star"></span>
    Star
  </a>

    <a class="social-count js-social-count" href="/quoideneuf/archivesspace/stargazers">
      0
    </a>

  </li>

  <li>
      <a href="/login?return_to=%2Fquoideneuf%2Farchivesspace"
        class="btn btn-sm btn-with-count tooltipped tooltipped-n"
        aria-label="You must be signed in to fork a repository" rel="nofollow">
        <span class="octicon octicon-repo-forked"></span>
        Fork
      </a>

    <a href="/quoideneuf/archivesspace/network" class="social-count">
      65
    </a>
  </li>
</ul>

          <h1 itemscope itemtype="http://data-vocabulary.org/Breadcrumb" class="entry-title public ">
  <span class="mega-octicon octicon-repo-forked"></span>
  <span class="author"><a href="/quoideneuf" class="url fn" itemprop="url" rel="author"><span itemprop="title">quoideneuf</span></a></span><!--
--><span class="path-divider">/</span><!--
--><strong><a href="/quoideneuf/archivesspace" data-pjax="#js-repo-pjax-container">archivesspace</a></strong>

  <span class="page-context-loader">
    <img alt="" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
  </span>

    <span class="fork-flag">
      <span class="text">forked from <a href="/archivesspace/archivesspace">archivesspace/archivesspace</a></span>
    </span>
</h1>

        </div>
      </div>
    </div>

    <div class="container">
      <div class="repository-with-sidebar repo-container new-discussion-timeline ">
        <div class="repository-sidebar clearfix">
          
<nav class="sunken-menu repo-nav js-repo-nav js-sidenav-container-pjax js-octicon-loaders"
     role="navigation"
     data-pjax="#js-repo-pjax-container"
     data-issue-count-url="/quoideneuf/archivesspace/issues/counts">
  <ul class="sunken-menu-group">
    <li class="tooltipped tooltipped-w" aria-label="Code">
      <a href="/quoideneuf/archivesspace/tree/js-unit-testing" aria-label="Code" aria-selected="true" class="js-selected-navigation-item selected sunken-menu-item" data-hotkey="g c" data-selected-links="repo_source repo_downloads repo_commits repo_releases repo_tags repo_branches /quoideneuf/archivesspace/tree/js-unit-testing">
        <span class="octicon octicon-code"></span> <span class="full-word">Code</span>
        <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>    </li>


    <li class="tooltipped tooltipped-w" aria-label="Pull requests">
      <a href="/quoideneuf/archivesspace/pulls" aria-label="Pull requests" class="js-selected-navigation-item sunken-menu-item" data-hotkey="g p" data-selected-links="repo_pulls /quoideneuf/archivesspace/pulls">
          <span class="octicon octicon-git-pull-request"></span> <span class="full-word">Pull requests</span>
          <span class="js-pull-replace-counter"></span>
          <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>    </li>

  </ul>
  <div class="sunken-menu-separator"></div>
  <ul class="sunken-menu-group">

    <li class="tooltipped tooltipped-w" aria-label="Pulse">
      <a href="/quoideneuf/archivesspace/pulse" aria-label="Pulse" class="js-selected-navigation-item sunken-menu-item" data-selected-links="pulse /quoideneuf/archivesspace/pulse">
        <span class="octicon octicon-pulse"></span> <span class="full-word">Pulse</span>
        <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>    </li>

    <li class="tooltipped tooltipped-w" aria-label="Graphs">
      <a href="/quoideneuf/archivesspace/graphs" aria-label="Graphs" class="js-selected-navigation-item sunken-menu-item" data-selected-links="repo_graphs repo_contributors /quoideneuf/archivesspace/graphs">
        <span class="octicon octicon-graph"></span> <span class="full-word">Graphs</span>
        <img alt="" class="mini-loader" height="16" src="https://assets-cdn.github.com/images/spinners/octocat-spinner-32.gif" width="16" />
</a>    </li>
  </ul>


</nav>

            <div class="only-with-full-nav">
                
<div class="js-clone-url clone-url open"
  data-protocol-type="http">
  <h3 class="text-small text-muted"><span class="text-emphasized">HTTPS</span> clone URL</h3>
  <div class="input-group js-zeroclipboard-container">
    <input type="text" class="input-mini text-small text-muted input-monospace js-url-field js-zeroclipboard-target"
           value="https://github.com/quoideneuf/archivesspace.git" readonly="readonly" aria-label="HTTPS clone URL">
    <span class="input-group-button">
      <button aria-label="Copy to clipboard" class="js-zeroclipboard btn btn-sm zeroclipboard-button tooltipped tooltipped-s" data-copied-hint="Copied!" type="button"><span class="octicon octicon-clippy"></span></button>
    </span>
  </div>
</div>

  
<div class="js-clone-url clone-url "
  data-protocol-type="subversion">
  <h3 class="text-small text-muted"><span class="text-emphasized">Subversion</span> checkout URL</h3>
  <div class="input-group js-zeroclipboard-container">
    <input type="text" class="input-mini text-small text-muted input-monospace js-url-field js-zeroclipboard-target"
           value="https://github.com/quoideneuf/archivesspace" readonly="readonly" aria-label="Subversion checkout URL">
    <span class="input-group-button">
      <button aria-label="Copy to clipboard" class="js-zeroclipboard btn btn-sm zeroclipboard-button tooltipped tooltipped-s" data-copied-hint="Copied!" type="button"><span class="octicon octicon-clippy"></span></button>
    </span>
  </div>
</div>



<div class="clone-options text-small text-muted">You can clone with
  <!-- </textarea> --><!-- '"` --><form accept-charset="UTF-8" action="/users/set_protocol?protocol_selector=http&amp;protocol_type=clone" class="inline-form js-clone-selector-form " data-form-nonce="f3eca5325eeea76f7305e4f40357a31fcf5ee7b2" data-remote="true" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /><input name="authenticity_token" type="hidden" value="b4e3aeNMVX1pmGOT5omzRDhAUAw8B2tt4uiA4XT26GpPnrZIVfP9VIi4nHP8I32cMRdkfSRNLnmWgxtsQO6tog==" /></div><button class="btn-link js-clone-selector" data-protocol="http" type="submit">HTTPS</button></form> or <!-- </textarea> --><!-- '"` --><form accept-charset="UTF-8" action="/users/set_protocol?protocol_selector=subversion&amp;protocol_type=clone" class="inline-form js-clone-selector-form " data-form-nonce="f3eca5325eeea76f7305e4f40357a31fcf5ee7b2" data-remote="true" method="post"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /><input name="authenticity_token" type="hidden" value="6A1Evk7VaGQXcXkAe16eqsE640SSMuVo+puoCHmDho61ofya3o1mdJkPoCRuuqZZKVPg2OkXpQbIbZavZW4hhA==" /></div><button class="btn-link js-clone-selector" data-protocol="subversion" type="submit">Subversion</button></form>.
  <a href="https://help.github.com/articles/which-remote-url-should-i-use" class="help tooltipped tooltipped-n" aria-label="Get help on which URL is right for you.">
    <span class="octicon octicon-question"></span>
  </a>
</div>

              <a href="/quoideneuf/archivesspace/archive/js-unit-testing.zip"
                 class="btn btn-sm sidebar-button"
                 aria-label="Download the contents of quoideneuf/archivesspace as a zip file"
                 title="Download the contents of quoideneuf/archivesspace as a zip file"
                 rel="nofollow">
                <span class="octicon octicon-cloud-download"></span>
                Download ZIP
              </a>
            </div>
        </div>
        <div id="js-repo-pjax-container" class="repository-content context-loader-container" data-pjax-container>

          

<a href="/quoideneuf/archivesspace/blob/1705f22b05461a2c390411f51f176695b37e6b07/frontend/README_JASMINE.md" class="hidden js-permalink-shortcut" data-hotkey="y">Permalink</a>

<!-- blob contrib key: blob_contributors:v21:f9301021fc08284e1094ec09d140fc97 -->

  <div class="file-navigation js-zeroclipboard-container">
    
<div class="select-menu js-menu-container js-select-menu left">
  <button class="btn btn-sm select-menu-button js-menu-target css-truncate" data-hotkey="w"
    title="js-unit-testing"
    type="button" aria-label="Switch branches or tags" tabindex="0" aria-haspopup="true">
    <i>Branch:</i>
    <span class="js-select-button css-truncate-target">js-unit-testing</span>
  </button>

  <div class="select-menu-modal-holder js-menu-content js-navigation-container" data-pjax aria-hidden="true">

    <div class="select-menu-modal">
      <div class="select-menu-header">
        <span class="octicon octicon-x js-menu-close" role="button" aria-label="Close"></span>
        <span class="select-menu-title">Switch branches/tags</span>
      </div>

      <div class="select-menu-filters">
        <div class="select-menu-text-filter">
          <input type="text" aria-label="Filter branches/tags" id="context-commitish-filter-field" class="js-filterable-field js-navigation-enable" placeholder="Filter branches/tags">
        </div>
        <div class="select-menu-tabs">
          <ul>
            <li class="select-menu-tab">
              <a href="#" data-tab-filter="branches" data-filter-placeholder="Filter branches/tags" class="js-select-menu-tab" role="tab">Branches</a>
            </li>
            <li class="select-menu-tab">
              <a href="#" data-tab-filter="tags" data-filter-placeholder="Find a tag…" class="js-select-menu-tab" role="tab">Tags</a>
            </li>
          </ul>
        </div>
      </div>

      <div class="select-menu-list select-menu-tab-bucket js-select-menu-tab-bucket" data-tab-filter="branches" role="menu">

        <div data-filterable-for="context-commitish-filter-field" data-filterable-type="substring">


            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/1065-shortcuts-restart/frontend/README_JASMINE.md"
               data-name="1065-shortcuts-restart"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="1065-shortcuts-restart">
                1065-shortcuts-restart
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/AR-1038-default-values/frontend/README_JASMINE.md"
               data-name="AR-1038-default-values"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="AR-1038-default-values">
                AR-1038-default-values
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/AR-1173/frontend/README_JASMINE.md"
               data-name="AR-1173"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="AR-1173">
                AR-1173
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/AR-1216-upgrade-typeahead/frontend/README_JASMINE.md"
               data-name="AR-1216-upgrade-typeahead"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="AR-1216-upgrade-typeahead">
                AR-1216-upgrade-typeahead
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/AR-1218-rde-dates/frontend/README_JASMINE.md"
               data-name="AR-1218-rde-dates"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="AR-1218-rde-dates">
                AR-1218-rde-dates
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/AR-1240-rde-extents/frontend/README_JASMINE.md"
               data-name="AR-1240-rde-extents"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="AR-1240-rde-extents">
                AR-1240-rde-extents
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/add_title_to_delete_confirmation/frontend/README_JASMINE.md"
               data-name="add_title_to_delete_confirmation"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="add_title_to_delete_confirmation">
                add_title_to_delete_confirmation
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/boostrap-three/frontend/README_JASMINE.md"
               data-name="boostrap-three"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="boostrap-three">
                boostrap-three
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/container-frontend/frontend/README_JASMINE.md"
               data-name="container-frontend"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="container-frontend">
                container-frontend
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/deceptive-import-failures/frontend/README_JASMINE.md"
               data-name="deceptive-import-failures"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="deceptive-import-failures">
                deceptive-import-failures
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/delete_feed_records_with_children/frontend/README_JASMINE.md"
               data-name="delete_feed_records_with_children"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="delete_feed_records_with_children">
                delete_feed_records_with_children
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/fix-append-method/frontend/README_JASMINE.md"
               data-name="fix-append-method"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="fix-append-method">
                fix-append-method
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/fop-fix/frontend/README_JASMINE.md"
               data-name="fop-fix"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="fop-fix">
                fop-fix
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/gh-pages/frontend/README_JASMINE.md"
               data-name="gh-pages"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="gh-pages">
                gh-pages
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open selected"
               href="/quoideneuf/archivesspace/blob/js-unit-testing/frontend/README_JASMINE.md"
               data-name="js-unit-testing"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="js-unit-testing">
                js-unit-testing
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/keyboard-shortcuts-travis-test/frontend/README_JASMINE.md"
               data-name="keyboard-shortcuts-travis-test"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="keyboard-shortcuts-travis-test">
                keyboard-shortcuts-travis-test
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/keyboard-shortcuts/frontend/README_JASMINE.md"
               data-name="keyboard-shortcuts"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="keyboard-shortcuts">
                keyboard-shortcuts
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/master/frontend/README_JASMINE.md"
               data-name="master"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="master">
                master
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/missing-frontend-plugin-hooks/frontend/README_JASMINE.md"
               data-name="missing-frontend-plugin-hooks"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="missing-frontend-plugin-hooks">
                missing-frontend-plugin-hooks
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/my-master/frontend/README_JASMINE.md"
               data-name="my-master"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="my-master">
                my-master
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/nuke-processing-started-date-fix/frontend/README_JASMINE.md"
               data-name="nuke-processing-started-date-fix"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="nuke-processing-started-date-fix">
                nuke-processing-started-date-fix
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/ordered-batch-imports/frontend/README_JASMINE.md"
               data-name="ordered-batch-imports"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="ordered-batch-imports">
                ordered-batch-imports
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/ordered-notes/frontend/README_JASMINE.md"
               data-name="ordered-notes"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="ordered-notes">
                ordered-notes
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/plugin-migrations-patch/frontend/README_JASMINE.md"
               data-name="plugin-migrations-patch"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="plugin-migrations-patch">
                plugin-migrations-patch
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/rde-templates/frontend/README_JASMINE.md"
               data-name="rde-templates"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="rde-templates">
                rde-templates
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/remove-one-child-node-from-one-tree-test/frontend/README_JASMINE.md"
               data-name="remove-one-child-node-from-one-tree-test"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="remove-one-child-node-from-one-tree-test">
                remove-one-child-node-from-one-tree-test
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/rights-unique-identifier-migration-fix/frontend/README_JASMINE.md"
               data-name="rights-unique-identifier-migration-fix"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="rights-unique-identifier-migration-fix">
                rights-unique-identifier-migration-fix
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/search-and-replace/frontend/README_JASMINE.md"
               data-name="search-and-replace"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="search-and-replace">
                search-and-replace
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/selenium-speedup/frontend/README_JASMINE.md"
               data-name="selenium-speedup"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="selenium-speedup">
                selenium-speedup
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/strip-out-note-mappings/frontend/README_JASMINE.md"
               data-name="strip-out-note-mappings"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="strip-out-note-mappings">
                strip-out-note-mappings
              </span>
            </a>
            <a class="select-menu-item js-navigation-item js-navigation-open "
               href="/quoideneuf/archivesspace/blob/travis-caching/frontend/README_JASMINE.md"
               data-name="travis-caching"
               data-skip-pjax="true"
               rel="nofollow">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <span class="select-menu-item-text css-truncate-target" title="travis-caching">
                travis-caching
              </span>
            </a>
        </div>

          <div class="select-menu-no-results">Nothing to show</div>
      </div>

      <div class="select-menu-list select-menu-tab-bucket js-select-menu-tab-bucket" data-tab-filter="tags">
        <div data-filterable-for="context-commitish-filter-field" data-filterable-type="substring">


            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.6.2/frontend/README_JASMINE.md"
                 data-name="v0.6.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.6.2">v0.6.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.6.1/frontend/README_JASMINE.md"
                 data-name="v0.6.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.6.1">v0.6.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.6.0/frontend/README_JASMINE.md"
                 data-name="v0.6.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.6.0">v0.6.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.5.4/frontend/README_JASMINE.md"
                 data-name="v0.5.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.5.4">v0.5.4</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.5.3/frontend/README_JASMINE.md"
                 data-name="v0.5.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.5.3">v0.5.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.5.2/frontend/README_JASMINE.md"
                 data-name="v0.5.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.5.2">v0.5.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.5.2-1/frontend/README_JASMINE.md"
                 data-name="v0.5.2-1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.5.2-1">v0.5.2-1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.5.1/frontend/README_JASMINE.md"
                 data-name="v0.5.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.5.1">v0.5.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.5.0/frontend/README_JASMINE.md"
                 data-name="v0.5.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.5.0">v0.5.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.4.3/frontend/README_JASMINE.md"
                 data-name="v0.4.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.4.3">v0.4.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v.0.4.2/frontend/README_JASMINE.md"
                 data-name="v.0.4.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v.0.4.2">v.0.4.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.4.2/frontend/README_JASMINE.md"
                 data-name="v0.4.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.4.2">v0.4.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.4.1/frontend/README_JASMINE.md"
                 data-name="v0.4.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.4.1">v0.4.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.4.0/frontend/README_JASMINE.md"
                 data-name="v0.4.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.4.0">v0.4.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.3.4/frontend/README_JASMINE.md"
                 data-name="v0.3.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.3.4">v0.3.4</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.3.3/frontend/README_JASMINE.md"
                 data-name="v0.3.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.3.3">v0.3.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.3.3-1/frontend/README_JASMINE.md"
                 data-name="v0.3.3-1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.3.3-1">v0.3.3-1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.3.2/frontend/README_JASMINE.md"
                 data-name="v0.3.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.3.2">v0.3.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.3.2-1/frontend/README_JASMINE.md"
                 data-name="v0.3.2-1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.3.2-1">v0.3.2-1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.3.1/frontend/README_JASMINE.md"
                 data-name="v0.3.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.3.1">v0.3.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.3.1-1/frontend/README_JASMINE.md"
                 data-name="v0.3.1-1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.3.1-1">v0.3.1-1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.3.0/frontend/README_JASMINE.md"
                 data-name="v0.3.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.3.0">v0.3.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.2.3/frontend/README_JASMINE.md"
                 data-name="v0.2.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.2.3">v0.2.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.2.3-2/frontend/README_JASMINE.md"
                 data-name="v0.2.3-2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.2.3-2">v0.2.3-2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.2.3-1/frontend/README_JASMINE.md"
                 data-name="v0.2.3-1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.2.3-1">v0.2.3-1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.2.2/frontend/README_JASMINE.md"
                 data-name="v0.2.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.2.2">v0.2.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.2.1/frontend/README_JASMINE.md"
                 data-name="v0.2.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.2.1">v0.2.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.2.0/frontend/README_JASMINE.md"
                 data-name="v0.2.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.2.0">v0.2.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.2.0-1/frontend/README_JASMINE.md"
                 data-name="v0.2.0-1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.2.0-1">v0.2.0-1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.1.3/frontend/README_JASMINE.md"
                 data-name="v0.1.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.1.3">v0.1.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.1.2/frontend/README_JASMINE.md"
                 data-name="v0.1.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.1.2">v0.1.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.1.2-2/frontend/README_JASMINE.md"
                 data-name="v0.1.2-2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.1.2-2">v0.1.2-2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.1.2-1/frontend/README_JASMINE.md"
                 data-name="v0.1.2-1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.1.2-1">v0.1.2-1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.1.1/frontend/README_JASMINE.md"
                 data-name="v0.1.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.1.1">v0.1.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.1.0/frontend/README_JASMINE.md"
                 data-name="v0.1.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.1.0">v0.1.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/v0.0.1/frontend/README_JASMINE.md"
                 data-name="v0.0.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="v0.0.1">v0.0.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/plugin-debug/frontend/README_JASMINE.md"
                 data-name="plugin-debug"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="plugin-debug">plugin-debug</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.5.4/frontend/README_JASMINE.md"
                 data-name="doc_v0.5.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.5.4">doc_v0.5.4</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.5.3/frontend/README_JASMINE.md"
                 data-name="doc_v0.5.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.5.3">doc_v0.5.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.5.2/frontend/README_JASMINE.md"
                 data-name="doc_v0.5.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.5.2">doc_v0.5.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.5.1/frontend/README_JASMINE.md"
                 data-name="doc_v0.5.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.5.1">doc_v0.5.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.5.0/frontend/README_JASMINE.md"
                 data-name="doc_v0.5.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.5.0">doc_v0.5.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.4.3/frontend/README_JASMINE.md"
                 data-name="doc_v0.4.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.4.3">doc_v0.4.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.4.2/frontend/README_JASMINE.md"
                 data-name="doc_v0.4.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.4.2">doc_v0.4.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.4.1/frontend/README_JASMINE.md"
                 data-name="doc_v0.4.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.4.1">doc_v0.4.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.4.0/frontend/README_JASMINE.md"
                 data-name="doc_v0.4.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.4.0">doc_v0.4.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.3.4/frontend/README_JASMINE.md"
                 data-name="doc_v0.3.4"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.3.4">doc_v0.3.4</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.3.3/frontend/README_JASMINE.md"
                 data-name="doc_v0.3.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.3.3">doc_v0.3.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.3.2/frontend/README_JASMINE.md"
                 data-name="doc_v0.3.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.3.2">doc_v0.3.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.3.0/frontend/README_JASMINE.md"
                 data-name="doc_v0.3.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.3.0">doc_v0.3.0</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.2.3/frontend/README_JASMINE.md"
                 data-name="doc_v0.2.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.2.3">doc_v0.2.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.2.2/frontend/README_JASMINE.md"
                 data-name="doc_v0.2.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.2.2">doc_v0.2.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.2.1/frontend/README_JASMINE.md"
                 data-name="doc_v0.2.1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.2.1">doc_v0.2.1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.2.0-1/frontend/README_JASMINE.md"
                 data-name="doc_v0.2.0-1"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.2.0-1">doc_v0.2.0-1</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.1.3/frontend/README_JASMINE.md"
                 data-name="doc_v0.1.3"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.1.3">doc_v0.1.3</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.1.2/frontend/README_JASMINE.md"
                 data-name="doc_v0.1.2"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.1.2">doc_v0.1.2</a>
            </div>
            <div class="select-menu-item js-navigation-item ">
              <span class="select-menu-item-icon octicon octicon-check"></span>
              <a href="/quoideneuf/archivesspace/tree/doc_v0.1.0/frontend/README_JASMINE.md"
                 data-name="doc_v0.1.0"
                 data-skip-pjax="true"
                 rel="nofollow"
                 class="js-navigation-open select-menu-item-text css-truncate-target"
                 title="doc_v0.1.0">doc_v0.1.0</a>
            </div>
        </div>

        <div class="select-menu-no-results">Nothing to show</div>
      </div>

    </div>
  </div>
</div>

    <div class="btn-group right">
      <a href="/quoideneuf/archivesspace/find/js-unit-testing"
            class="js-show-file-finder btn btn-sm empty-icon tooltipped tooltipped-nw"
            data-pjax
            data-hotkey="t"
            aria-label="Quickly jump between files">
        <span class="octicon octicon-list-unordered"></span>
      </a>
      <button aria-label="Copy file path to clipboard" class="js-zeroclipboard btn btn-sm zeroclipboard-button tooltipped tooltipped-s" data-copied-hint="Copied!" type="button"><span class="octicon octicon-clippy"></span></button>
    </div>

    <div class="breadcrumb js-zeroclipboard-target">
      <span class="repo-root js-repo-root"><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/quoideneuf/archivesspace/tree/js-unit-testing" class="" data-branch="js-unit-testing" data-pjax="true" itemscope="url"><span itemprop="title">archivesspace</span></a></span></span><span class="separator">/</span><span itemscope="" itemtype="http://data-vocabulary.org/Breadcrumb"><a href="/quoideneuf/archivesspace/tree/js-unit-testing/frontend" class="" data-branch="js-unit-testing" data-pjax="true" itemscope="url"><span itemprop="title">frontend</span></a></span><span class="separator">/</span><strong class="final-path">README_JASMINE.md</strong>
    </div>
  </div>


  <div class="commit-tease">
      <span class="right">
        <a class="commit-tease-sha" href="/quoideneuf/archivesspace/commit/ba1edbe21b0eb8a379f4c67851092b6a4018763e" data-pjax>
          ba1edbe
        </a>
        <time datetime="2015-10-21T01:06:51Z" is="relative-time">Oct 20, 2015</time>
      </span>
      <div>
        <img alt="@quoideneuf" class="avatar" height="20" src="https://avatars3.githubusercontent.com/u/1626547?v=3&amp;s=40" width="20" />
        <a href="/quoideneuf" class="user-mention" rel="author">quoideneuf</a>
          <a href="/quoideneuf/archivesspace/commit/ba1edbe21b0eb8a379f4c67851092b6a4018763e" class="message" data-pjax="true" title="initial commit of js unit testing setup">initial commit of js unit testing setup</a>
      </div>

    <div class="commit-tease-contributors">
      <a class="muted-link contributors-toggle" href="#blob_contributors_box" rel="facebox">
        <strong>1</strong>
         contributor
      </a>
      
    </div>

    <div id="blob_contributors_box" style="display:none">
      <h2 class="facebox-header" data-facebox-id="facebox-header">Users who have contributed to this file</h2>
      <ul class="facebox-user-list" data-facebox-id="facebox-description">
          <li class="facebox-user-list-item">
            <img alt="@quoideneuf" height="24" src="https://avatars1.githubusercontent.com/u/1626547?v=3&amp;s=48" width="24" />
            <a href="/quoideneuf">quoideneuf</a>
          </li>
      </ul>
    </div>
  </div>

<div class="file">
  <div class="file-header">
  <div class="file-actions">

    <div class="btn-group">
      <a href="/quoideneuf/archivesspace/raw/js-unit-testing/frontend/README_JASMINE.md" class="btn btn-sm " id="raw-url">Raw</a>
        <a href="/quoideneuf/archivesspace/blame/js-unit-testing/frontend/README_JASMINE.md" class="btn btn-sm js-update-url-with-hash">Blame</a>
      <a href="/quoideneuf/archivesspace/commits/js-unit-testing/frontend/README_JASMINE.md" class="btn btn-sm " rel="nofollow">History</a>
    </div>


        <button type="button" class="octicon-btn disabled tooltipped tooltipped-nw"
          aria-label="You must be signed in to make or propose changes">
          <span class="octicon octicon-pencil"></span>
        </button>
        <button type="button" class="octicon-btn octicon-btn-danger disabled tooltipped tooltipped-nw"
          aria-label="You must be signed in to make or propose changes">
          <span class="octicon octicon-trashcan"></span>
        </button>
  </div>

  <div class="file-info">
      11 lines (7 sloc)
      <span class="file-info-divider"></span>
    279 Bytes
  </div>
</div>

  
  <div id="readme" class="blob instapaper_body">
    <article class="markdown-body entry-content" itemprop="mainContentOfPage"><h1><a id="user-content-unit-testing-frontend-assets-with-jasmine" class="anchor" href="#unit-testing-frontend-assets-with-jasmine" aria-hidden="true"><span class="octicon octicon-link"></span></a>Unit Testing Frontend Assets with Jasmine</h1>

<p>This is a proof of concept and is under development.</p>

<p>To run JS Unit tests, install NPM and:</p>

<pre><code>cd archivesspace/frontend
npm install
$(npm bin)/karma start jasmine/my.conf.js --single-run
</code></pre>
</article>
  </div>

</div>

<a href="#jump-to-line" rel="facebox[.linejump]" data-hotkey="l" style="display:none">Jump to Line</a>
<div id="jump-to-line" style="display:none">
  <!-- </textarea> --><!-- '"` --><form accept-charset="UTF-8" action="" class="js-jump-to-line-form" method="get"><div style="margin:0;padding:0;display:inline"><input name="utf8" type="hidden" value="&#x2713;" /></div>
    <input class="linejump-input js-jump-to-line-field" type="text" placeholder="Jump to line&hellip;" aria-label="Jump to line" autofocus>
    <button type="submit" class="btn">Go</button>
</form></div>

        </div>
      </div>
      <div class="modal-backdrop"></div>
    </div>
  </div>


    </div>

      <div class="container">
  <div class="site-footer" role="contentinfo">
    <ul class="site-footer-links right">
        <li><a href="https://status.github.com/" data-ga-click="Footer, go to status, text:status">Status</a></li>
      <li><a href="https://developer.github.com" data-ga-click="Footer, go to api, text:api">API</a></li>
      <li><a href="https://training.github.com" data-ga-click="Footer, go to training, text:training">Training</a></li>
      <li><a href="https://shop.github.com" data-ga-click="Footer, go to shop, text:shop">Shop</a></li>
        <li><a href="https://github.com/blog" data-ga-click="Footer, go to blog, text:blog">Blog</a></li>
        <li><a href="https://github.com/about" data-ga-click="Footer, go to about, text:about">About</a></li>
        <li><a href="https://github.com/pricing" data-ga-click="Footer, go to pricing, text:pricing">Pricing</a></li>

    </ul>

    <a href="https://github.com" aria-label="Homepage">
      <span class="mega-octicon octicon-mark-github" title="GitHub"></span>
</a>
    <ul class="site-footer-links">
      <li>&copy; 2015 <span title="0.06099s from github-fe132-cp1-prd.iad.github.net">GitHub</span>, Inc.</li>
        <li><a href="https://github.com/site/terms" data-ga-click="Footer, go to terms, text:terms">Terms</a></li>
        <li><a href="https://github.com/site/privacy" data-ga-click="Footer, go to privacy, text:privacy">Privacy</a></li>
        <li><a href="https://github.com/security" data-ga-click="Footer, go to security, text:security">Security</a></li>
        <li><a href="https://github.com/contact" data-ga-click="Footer, go to contact, text:contact">Contact</a></li>
        <li><a href="https://help.github.com" data-ga-click="Footer, go to help, text:help">Help</a></li>
    </ul>
  </div>
</div>



    
    
    

    <div id="ajax-error-message" class="flash flash-error">
      <span class="octicon octicon-alert"></span>
      <button type="button" class="flash-close js-flash-close js-ajax-error-dismiss" aria-label="Dismiss error">
        <span class="octicon octicon-x"></span>
      </button>
      Something went wrong with that request. Please try again.
    </div>


      <script crossorigin="anonymous" src="https://assets-cdn.github.com/assets/frameworks-2e7fc3d264a208e1383de85b815379beccff56c1f977714515d4cac7820eef3e.js"></script>
      <script async="async" crossorigin="anonymous" src="https://assets-cdn.github.com/assets/github-e3b6c0d7324e75ba03f85bd9a58697e1fb0c02d10c9326805d511fa6cb6a0d21.js"></script>
      
      
    <div class="js-stale-session-flash stale-session-flash flash flash-warn flash-banner hidden">
      <span class="octicon octicon-alert"></span>
      <span class="signed-in-tab-flash">You signed in with another tab or window. <a href="">Reload</a> to refresh your session.</span>
      <span class="signed-out-tab-flash">You signed out in another tab or window. <a href="">Reload</a> to refresh your session.</span>
    </div>
  </body>
</html>

