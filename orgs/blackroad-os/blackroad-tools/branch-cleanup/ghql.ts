import { Octokit } from '@octokit/core';
import { paginateGraphQL } from '@octokit/plugin-paginate-graphql';

const OctokitWithPlugins = Octokit.plugin(paginateGraphQL);

export interface MergedPR {
  number: number;
  mergedAt: string;
  headRefName: string;
  headRefOid: string;
  baseRefName: string;
}

export interface BranchInfo {
  name: string;
  protected: boolean;
  exists: boolean;
}

export interface CompareResult {
  status: 'ahead' | 'behind' | 'identical' | 'diverged';
  ahead_by: number;
  behind_by: number;
}

export class GitHubQLClient {
  private octokit: InstanceType<typeof OctokitWithPlugins>;

  constructor(token: string) {
    this.octokit = new OctokitWithPlugins({ auth: token });
  }

  async getDefaultBranch(owner: string, repo: string): Promise<string> {
    const { data } = await this.octokit.request('GET /repos/{owner}/{repo}', {
      owner,
      repo,
    });
    return data.default_branch;
  }

  async getMergedPRs(owner: string, repo: string): Promise<MergedPR[]> {
    const query = `
      query($owner: String!, $repo: String!, $cursor: String) {
        repository(owner: $owner, name: $repo) {
          pullRequests(first: 100, after: $cursor, states: MERGED, orderBy: {field: UPDATED_AT, direction: DESC}) {
            pageInfo {
              hasNextPage
              endCursor
            }
            nodes {
              number
              mergedAt
              headRefName
              headRefOid
              baseRefName
            }
          }
        }
      }
    `;

    const results: MergedPR[] = [];
    const iterator = this.octokit.graphql.paginate.iterator(query, {
      owner,
      repo,
    });

    for await (const response of iterator) {
      const prs = response.repository.pullRequests.nodes;
      results.push(...prs);
    }

    return results;
  }

  async checkBranch(owner: string, repo: string, branch: string): Promise<BranchInfo> {
    try {
      const { data } = await this.octokit.request('GET /repos/{owner}/{repo}/branches/{branch}', {
        owner,
        repo,
        branch,
      });
      return {
        name: branch,
        protected: data.protected,
        exists: true,
      };
    } catch (error: any) {
      if (error.status === 404) {
        return { name: branch, protected: false, exists: false };
      }
      throw error;
    }
  }

  async compareCommits(owner: string, repo: string, base: string, head: string): Promise<CompareResult> {
    try {
      const { data } = await this.octokit.request('GET /repos/{owner}/{repo}/compare/{basehead}', {
        owner,
        repo,
        basehead: `${base}...${head}`,
      });

      return {
        status: data.status as CompareResult['status'],
        ahead_by: data.ahead_by,
        behind_by: data.behind_by,
      };
    } catch (error: any) {
      if (error.status === 404) {
        // Branch might be deleted already
        return { status: 'diverged', ahead_by: 0, behind_by: 0 };
      }
      throw error;
    }
  }

  async isBranchReachable(owner: string, repo: string, base: string, head: string): Promise<boolean> {
    const result = await this.compareCommits(owner, repo, base, head);

    // Safe to delete if:
    // - behind (head is behind base, so fully contained)
    // - identical (head === base)
    // NOT safe if ahead (has commits not in base)
    return result.status === 'behind' || result.status === 'identical';
  }

  getOctokit() {
    return this.octokit;
  }
}
