import {readFileSync} from "node:fs";
import {spawn} from "node:child_process";

const port = 3200;
const contract = readFileSync("docs/openapi.yaml", "utf8");
const operations = [
  ["/api/repos", "get", "listRepositories"],
  ["/api/repos", "post", "createRepository"],
  ["/api/repos/{repo}", "get", "getRepository"],
  ["/api/repos/{repo}", "patch", "updateRepository"],
  ["/api/repos/{repo}", "delete", "softDeleteRepository"],
  ["/api/repos/{repo}/purge", "post", "purgeRepository"],
  ["/api/repos/{repo}/pulls", "get", "listPullRequests"],
  ["/api/repos/{repo}/pulls", "post", "createPullRequest"],
  ["/api/repos/{repo}/pulls/{pull}", "get", "getPullRequest"],
  ["/api/repos/{repo}/pulls/{pull}", "patch", "updatePullRequestState"],
  ["/api/repos/{repo}/pulls/{pull}/merge", "put", "mergePullRequest"],
  ["/api/repos/{repo}/pulls/{pull}/reviews", "get", "listPullRequestReviews"],
  ["/api/repos/{repo}/pulls/{pull}/reviews", "post", "createPullRequestReview"],
  ["/api/repos/{repo}/pulls/{pull}/comments", "get", "listPullRequestComments"],
  ["/api/repos/{repo}/pulls/{pull}/comments", "post", "createPullRequestComment"],
  ["/api/repos/{repo}/issues", "get", "listIssues"],
  ["/api/repos/{repo}/issues", "post", "createIssue"],
  ["/api/repos/{repo}/issues/{issue}", "get", "getIssue"],
  ["/api/repos/{repo}/issues/{issue}", "patch", "updateIssue"],
  ["/api/repos/{repo}/issues/{issue}/comments", "get", "listIssueComments"],
  ["/api/repos/{repo}/issues/{issue}/comments", "post", "createIssueComment"],
  ["/api/repos/{repo}/issues/{issue}/labels", "get", "listIssueLabels"],
  ["/api/repos/{repo}/issues/{issue}/labels", "post", "addIssueLabel"],
  ["/api/repos/{repo}/issues/{issue}/labels/{label}", "delete", "removeIssueLabel"],
  ["/api/repos/{repo}/issues/{issue}/assignees", "get", "listIssueAssignees"],
  ["/api/repos/{repo}/issues/{issue}/assignees", "post", "addIssueAssignee"],
  ["/api/repos/{repo}/issues/{issue}/assignees/{actor}", "delete", "removeIssueAssignee"],
  ["/api/repos/{repo}/activity", "get", "listRepositoryActivity"],
  ["/api/repos/{repo}/audit", "get", "listRepositoryAudit"],
  ["/api/repos/{repo}/commits", "get", "listCommits"],
  ["/api/repos/{repo}/commits/{oid}", "get", "getCommit"],
  ["/api/repos/{repo}/contents/{path}", "get", "getContents"],
  ["/api/repos/{repo}/contents/{path}", "put", "updateContents"],
  ["/api/repos/{repo}/compare", "get", "compareReferences"],
  ["/api/repos/{repo}/branches", "get", "listBranches"],
  ["/api/repos/{repo}/branches", "post", "createBranch"],
  ["/api/repos/{repo}/branches/{branch}", "get", "getBranch"],
  ["/api/repos/{repo}/branches/{branch}", "patch", "updateBranch"],
  ["/api/repos/{repo}/branches/{branch}", "delete", "deleteBranch"],
  ["/api/repos/{repo}/tags", "get", "listTags"],
  ["/api/repos/{repo}/tags", "post", "createTag"],
  ["/api/repos/{repo}/tags/{tag}", "get", "getTag"],
  ["/api/repos/{repo}/tags/{tag}", "patch", "updateTag"],
  ["/api/repos/{repo}/tags/{tag}", "delete", "deleteTag"],
];

function fail(message) {
  throw new Error(`REST contract: ${message}`);
}

for (const [path, method, operationId] of operations) {
  const pathOffset = contract.indexOf(`  ${path}:`);
  if (pathOffset < 0) fail(`missing path ${path}`);
  const operationOffset = contract.indexOf(`    ${method}:`, pathOffset);
  if (operationOffset < 0) fail(`missing ${method.toUpperCase()} ${path}`);
  const nextPath = contract.indexOf("\n  /", pathOffset + 3);
  const operation = contract.slice(operationOffset, nextPath < 0 ? undefined : nextPath);
  if (!operation.includes(`operationId: ${operationId}`)) {
    fail(`missing operationId ${operationId}`);
  }
}

function assertRepository(value) {
  if (!value || typeof value.id !== "string" || typeof value.name !== "string"
      || typeof value.description !== "string"
      || typeof value.default_branch !== "string"
      || !Number.isInteger(value.version)) {
    fail("repository response did not match the Repository schema");
  }
}

function assertReference(value, prefix) {
  if (!value || typeof value.name !== "string"
      || !value.name.startsWith(prefix)
      || value.algorithm !== "sha1" || typeof value.oid !== "string"
      || !/^[0-9a-f]{40}$/i.test(value.oid)
      || !Number.isInteger(value.version)) {
    fail("reference response did not match the Reference schema");
  }
}

function assertCommit(value) {
  if (!value || typeof value.oid !== "string"
      || !/^[0-9a-f]{40}$/i.test(value.oid)
      || value.algorithm !== "sha1" || typeof value.tree !== "string"
      || !Array.isArray(value.parents) || typeof value.author !== "string"
      || typeof value.committer !== "string" || typeof value.message !== "string") {
    fail("commit response did not match the Commit schema");
  }
}

const child = spawn(process.execPath, ["server/index.mjs"], {
  env: {
    ...process.env,
    HITHUB_PORT: String(port),
    HITHUB_FIXTURE_REPOSITORY: "compare-fixture",
  },
  stdio: "inherit",
});

async function request(path, options) {
  const response = await fetch(`http://127.0.0.1:${port}${path}`, options);
  let body = null;
  if (response.status !== 204) body = await response.json();
  return {response, body};
}

try {
  let healthy = false;
  for (let attempt = 0; attempt < 50; attempt += 1) {
    try {
      healthy = (await fetch(`http://127.0.0.1:${port}/health`)).ok;
      if (healthy) break;
    } catch (_error) {
      await new Promise((resolve) => setTimeout(resolve, 100));
    }
  }
  if (!healthy) fail("server did not start");

  const created = await request("/api/repos", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({name: "contract-repository"}),
  });
  if (created.response.status !== 201) fail(`create returned ${created.response.status}`);
  assertRepository(created.body);

  const listed = await request("/api/repos");
  if (listed.response.status !== 200 || !Array.isArray(listed.body)) {
    fail("repository list did not return an array");
  }
  listed.body.forEach(assertRepository);

  const retrieved = await request("/api/repos/contract-repository");
  if (retrieved.response.status !== 200) fail("repository retrieve failed");
  assertRepository(retrieved.body);

  const commits = await request("/api/repos/contract-repository/commits?ref=main");
  if (commits.response.status !== 200 || !Array.isArray(commits.body)
      || commits.body.length !== 1) {
    fail("commit history did not return the initial commit");
  }
  commits.body.forEach(assertCommit);
  const commit = await request(
    `/api/repos/contract-repository/commits/${commits.body[0].oid}`,
  );
  if (commit.response.status !== 200) fail("commit retrieve failed");
  assertCommit(commit.body);

  const retryFirst = await request("/api/repos", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "idempotency-key": "contract-retry",
    },
    body: JSON.stringify({name: "retry-repository"}),
  });
  const retrySecond = await request("/api/repos", {
    method: "POST",
    headers: {
      "content-type": "application/json",
      "idempotency-key": "contract-retry",
    },
    body: JSON.stringify({name: "retry-repository"}),
  });
  if (retryFirst.response.status !== 201 || retrySecond.response.status !== 201
      || retryFirst.body?.id !== retrySecond.body?.id) {
    fail("idempotent repository retry did not replay the original result");
  }

  const branch = await request("/api/repos/contract-repository/branches", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      name: "contract",
      oid: "1111111111111111111111111111111111111111",
    }),
  });
  if (branch.response.status !== 201) fail("branch create failed");
  assertReference(branch.body, "refs/heads/");

  const tag = await request("/api/repos/contract-repository/tags", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({
      name: "contract",
      oid: "2222222222222222222222222222222222222222",
    }),
  });
  if (tag.response.status !== 201) fail("tag create failed");
  assertReference(tag.body, "refs/tags/");

  const duplicate = await request("/api/repos", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({name: "CONTRACT-REPOSITORY"}),
  });
  if (duplicate.response.status !== 409
      || duplicate.response.headers.get("content-type")
        ?.includes("application/problem+json") !== true
      || duplicate.body?.status !== 409) {
    fail("problem response did not match the documented Conflict response");
  }
  const invalid = await request("/api/repos", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({description: "missing name"}),
  });
  if (invalid.response.status !== 400 || invalid.body?.status !== 400) {
    fail("invalid create did not match the documented BadRequest response");
  }
  const missingPrecondition = await request(
    "/api/repos/contract-repository",
    {
      method: "PATCH",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({description: "missing If-Match"}),
    },
  );
  if (missingPrecondition.response.status !== 428
      || missingPrecondition.body?.status !== 428) {
    fail("missing If-Match did not match the documented precondition response");
  }
  const firstUpdate = await request(
    "/api/repos/contract-repository",
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"1"',
      },
      body: JSON.stringify({description: "first writer"}),
    },
  );
  if (firstUpdate.response.status !== 200 || firstUpdate.body?.version !== 2) {
    fail("first concurrent update did not succeed");
  }
  const staleUpdate = await request(
    "/api/repos/contract-repository",
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"1"',
      },
      body: JSON.stringify({description: "stale writer"}),
    },
  );
  if (staleUpdate.response.status !== 412 || staleUpdate.body?.status !== 412) {
    fail("stale concurrent update did not match the documented response");
  }

  const pullRequestPayload = {
    source_ref: "refs/heads/feature",
    target_ref: "refs/heads/main",
    base_oid: "base-contract",
    head_oid: "head-contract",
  };
  const pullRequest = await request(
    "/api/repos/contract-repository/pulls",
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify(pullRequestPayload),
    },
  );
  if (pullRequest.response.status !== 201
      || pullRequest.body?.id !== "1"
      || pullRequest.body?.state !== "draft") {
    fail("the first pull request was not numbered #1");
  }
  const pullId = pullRequest.body.id;
  const rejectedPullId = await request(
    "/api/repos/contract-repository/pulls",
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({...pullRequestPayload, id: "chosen-by-client"}),
    },
  );
  if (rejectedPullId.response.status !== 400) {
    fail("a client-supplied pull-request id was accepted");
  }
  const pullRetryFirst = await request(
    "/api/repos/contract-repository/pulls",
    {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "idempotency-key": "contract-pull-retry",
      },
      body: JSON.stringify({...pullRequestPayload, source_ref: "refs/heads/retry"}),
    },
  );
  const pullRetrySecond = await request(
    "/api/repos/contract-repository/pulls",
    {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "idempotency-key": "contract-pull-retry",
      },
      body: JSON.stringify({...pullRequestPayload, source_ref: "refs/heads/retry"}),
    },
  );
  if (pullRetryFirst.response.status !== 201
      || pullRetrySecond.response.status !== 201
      || pullRetryFirst.body?.id !== "2"
      || pullRetrySecond.body?.id !== "2") {
    fail("a retried pull-request create consumed a second number");
  }
  const pullRequestList = await request(
    "/api/repos/contract-repository/pulls",
  );
  if (pullRequestList.response.status !== 200
      || !Array.isArray(pullRequestList.body)
      || pullRequestList.body.map((item) => item.id).join(",") !== "2,1") {
    fail("pull-request list was not ordered by descending number");
  }
  const pullRequestGet = await request(
    `/api/repos/contract-repository/pulls/${pullId}`,
  );
  if (pullRequestGet.response.status !== 200
      || pullRequestGet.body?.head_oid !== pullRequestPayload.head_oid) {
    fail("pull-request retrieve did not return the created request");
  }
  const readyForReview = await request(
    `/api/repos/contract-repository/pulls/${pullId}`,
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"1"',
      },
      body: JSON.stringify({state: "open"}),
    },
  );
  if (readyForReview.response.status !== 200
      || readyForReview.body?.state !== "open"
      || readyForReview.body?.version !== 2) {
    fail("pull-request ready-for-review transition failed");
  }
  const closedPullRequest = await request(
    `/api/repos/contract-repository/pulls/${pullId}`,
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"2"',
      },
      body: JSON.stringify({state: "closed"}),
    },
  );
  if (closedPullRequest.response.status !== 200
      || closedPullRequest.body?.state !== "closed"
      || closedPullRequest.body?.version !== 3) {
    fail("pull-request close transition failed");
  }
  const reopenedPullRequest = await request(
    `/api/repos/contract-repository/pulls/${pullId}`,
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"3"',
      },
      body: JSON.stringify({state: "open"}),
    },
  );
  if (reopenedPullRequest.response.status !== 200
      || reopenedPullRequest.body?.state !== "open"
      || reopenedPullRequest.body?.version !== 4) {
    fail("pull-request reopen transition failed");
  }
  const mergedPullRequest = await request(
    `/api/repos/contract-repository/pulls/${pullId}`,
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"4"',
      },
      body: JSON.stringify({state: "merged"}),
    },
  );
  if (mergedPullRequest.response.status !== 200
      || mergedPullRequest.body?.state !== "merged"
      || mergedPullRequest.body?.version !== 5) {
    fail("pull-request merge-state transition failed");
  }

  const issuePayload = {title: "Contract issue", body: "body"};
  const issue = await request(
    "/api/repos/contract-repository/issues",
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify(issuePayload),
    },
  );
  if (issue.response.status !== 201 || issue.body?.id !== "3"
      || issue.body?.state !== "open" || issue.body?.version !== 1) {
    fail("issues did not continue the sequence the pull requests started");
  }
  const issueId = issue.body.id;
  if (issue.response.headers.get("location")
      !== `/api/repos/contract-repository/issues/${issueId}`) {
    fail("issue create did not point Location at the numbered issue");
  }
  const rejectedId = await request(
    "/api/repos/contract-repository/issues",
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({id: "chosen-by-client", title: "Rejected"}),
    },
  );
  if (rejectedId.response.status !== 400) {
    fail("a client-supplied issue id was accepted");
  }
  const secondIssue = await request(
    "/api/repos/contract-repository/issues",
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({title: "Second contract issue"}),
    },
  );
  if (secondIssue.response.status !== 201 || secondIssue.body?.id !== "4") {
    fail("issue numbering was not sequential");
  }
  const issueRetryFirst = await request(
    "/api/repos/contract-repository/issues",
    {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "idempotency-key": "contract-issue-retry",
      },
      body: JSON.stringify({title: "Retried contract issue"}),
    },
  );
  const issueRetrySecond = await request(
    "/api/repos/contract-repository/issues",
    {
      method: "POST",
      headers: {
        "content-type": "application/json",
        "idempotency-key": "contract-issue-retry",
      },
      body: JSON.stringify({title: "Retried contract issue"}),
    },
  );
  if (issueRetryFirst.response.status !== 201
      || issueRetrySecond.response.status !== 201
      || issueRetryFirst.body?.id !== "5"
      || issueRetrySecond.body?.id !== "5") {
    fail("a retried issue create consumed a second number");
  }
  const issueList = await request("/api/repos/contract-repository/issues");
  if (issueList.response.status !== 200 || !Array.isArray(issueList.body)
      || issueList.body.map((item) => item.id).join(",") !== "5,4,3") {
    fail("issue list was not ordered by descending issue number");
  }
  const numberedPulls = await request("/api/repos/contract-repository/pulls");
  const takenNumbers = [
    ...numberedPulls.body.map((item) => item.id),
    ...issueList.body.map((item) => item.id),
  ];
  if (new Set(takenNumbers).size !== takenNumbers.length) {
    fail("an issue and a pull request share the same number");
  }
  const issueGet = await request(
    `/api/repos/contract-repository/issues/${issueId}`,
  );
  if (issueGet.response.status !== 200
      || issueGet.body?.title !== issuePayload.title) {
    fail("issue retrieve did not return the created issue");
  }
  const issueUpdate = await request(
    `/api/repos/contract-repository/issues/${issueId}`,
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"1"',
      },
      body: JSON.stringify({title: "Updated issue"}),
    },
  );
  if (issueUpdate.response.status !== 200
      || issueUpdate.body?.title !== "Updated issue"
      || issueUpdate.body?.version !== 2) {
    fail("issue update did not use the expected version");
  }
  const issueClose = await request(
    `/api/repos/contract-repository/issues/${issueId}`,
    {
      method: "PATCH",
      headers: {
        "content-type": "application/json",
        "if-match": '"2"',
      },
      body: JSON.stringify({state: "closed"}),
    },
  );
  if (issueClose.response.status !== 200
      || issueClose.body?.state !== "closed"
      || issueClose.body?.version !== 3) {
    fail("issue close transition failed");
  }
  const issueComment = await request(
    `/api/repos/contract-repository/issues/${issueId}/comments`,
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({id: "contract-comment", body: "A comment"}),
    },
  );
  if (issueComment.response.status !== 201
      || issueComment.body?.id !== "contract-comment") {
    fail("issue comment create failed");
  }
  const issueComments = await request(
    `/api/repos/contract-repository/issues/${issueId}/comments`,
  );
  if (issueComments.response.status !== 200
      || !Array.isArray(issueComments.body)
      || issueComments.body.length !== 1) {
    fail("issue comment list failed");
  }
  const activity = await request(
    "/api/repos/contract-repository/activity",
  );
  if (activity.response.status !== 200 || !Array.isArray(activity.body)
      || !activity.body.some((item) => item.action === "issue.create")
      || !activity.body.some((item) => item.action === "issue.comment")) {
    fail("repository activity did not include issue events");
  }
  const label = await request(
    `/api/repos/contract-repository/issues/${issueId}/labels`,
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({label: "contract"}),
    },
  );
  if (label.response.status !== 201 || label.body?.label !== "contract") {
    fail("issue label create failed");
  }
  const duplicateLabel = await request(
    `/api/repos/contract-repository/issues/${issueId}/labels`,
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({label: "contract"}),
    },
  );
  if (duplicateLabel.response.status !== 409) {
    fail("duplicate issue label was not rejected");
  }
  const labels = await request(
    `/api/repos/contract-repository/issues/${issueId}/labels`,
  );
  if (labels.response.status !== 200
      || labels.body?.length !== 1 || labels.body[0]?.label !== "contract") {
    fail("issue label list did not return the applied label");
  }
  const assignee = await request(
    `/api/repos/contract-repository/issues/${issueId}/assignees`,
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({actor: "contract-actor"}),
    },
  );
  if (assignee.response.status !== 201
      || assignee.body?.actor !== "contract-actor") {
    fail("issue assignee create failed");
  }
  const assignees = await request(
    `/api/repos/contract-repository/issues/${issueId}/assignees`,
  );
  if (assignees.response.status !== 200 || assignees.body?.length !== 1
      || assignees.body[0]?.actor !== "contract-actor") {
    fail("issue assignee list did not return the added actor");
  }
  const removedLabel = await request(
    `/api/repos/contract-repository/issues/${issueId}/labels/contract`,
    {method: "DELETE"},
  );
  if (removedLabel.response.status !== 204) fail("issue label delete failed");
  const missingLabel = await request(
    `/api/repos/contract-repository/issues/${issueId}/labels/contract`,
    {method: "DELETE"},
  );
  if (missingLabel.response.status !== 404) {
    fail("removing an absent label did not return the documented 404");
  }

  const review = await request(
    `/api/repos/contract-repository/pulls/${pullId}/reviews`,
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({
        id: "contract-review", state: "approved", body: "Looks correct",
      }),
    },
  );
  if (review.response.status !== 201 || review.body?.state !== "approved"
      || typeof review.body?.actor !== "string") {
    fail("pull-request review create failed");
  }
  const invalidReview = await request(
    `/api/repos/contract-repository/pulls/${pullId}/reviews`,
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({id: "contract-review-2", state: "shipit"}),
    },
  );
  if (invalidReview.response.status !== 400) {
    fail("an unknown review state was not rejected");
  }
  const reviews = await request(
    `/api/repos/contract-repository/pulls/${pullId}/reviews`,
  );
  if (reviews.response.status !== 200 || reviews.body?.length !== 1
      || reviews.body[0]?.id !== "contract-review") {
    fail("pull-request review list did not return the created review");
  }
  const pullComment = await request(
    `/api/repos/contract-repository/pulls/${pullId}/comments`,
    {
      method: "POST",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({id: "contract-pull-comment", body: "One remark"}),
    },
  );
  if (pullComment.response.status !== 201) fail("pull-request comment create failed");
  const pullComments = await request(
    `/api/repos/contract-repository/pulls/${pullId}/comments`,
  );
  if (pullComments.response.status !== 200 || pullComments.body?.length !== 1
      || pullComments.body[0]?.body !== "One remark") {
    fail("pull-request comment list did not return the created comment");
  }
  const missingPullReviews = await request(
    "/api/repos/contract-repository/pulls/absent-pull-request/reviews",
  );
  if (missingPullReviews.response.status !== 404) {
    fail("reviews for an unknown pull request did not return 404");
  }

  const identical = await request(
    "/api/repos/contract-repository/compare?base=main&head=main",
  );
  if (identical.response.status !== 200
      || !Array.isArray(identical.body?.files)
      || identical.body.files.length !== 0
      || identical.body.summary?.total !== 0) {
    fail("comparing a reference with itself did not return an empty comparison");
  }
  const comparison = await request(
    "/api/repos/compare-fixture/compare?base=refs/heads/main&head=refs/heads/feature",
  );
  if (comparison.response.status !== 200
      || comparison.body?.files?.length !== 1
      || comparison.body.files[0].path !== "README"
      || comparison.body.files[0].status !== "modified"
      || comparison.body.files[0].binary !== false
      || comparison.body.additions !== 1 || comparison.body.deletions !== 1
      || comparison.body.summary?.modified !== 1
      || comparison.body.merge_base_oid !== comparison.body.base_oid) {
    fail("branch comparison did not report the changed README");
  }
  const patch = comparison.body.files[0].patch;
  if (!patch.includes("--- a/README") || !patch.includes("+++ b/README")
      || !patch.includes("@@ -1,1 +1,1 @@")
      || !patch.includes("-hello") || !patch.includes("+feature")) {
    fail("branch comparison did not return a unified diff");
  }
  const missingComparison = await request(
    "/api/repos/compare-fixture/compare?base=refs/heads/main&head=refs/heads/absent",
  );
  if (missingComparison.response.status !== 404
      || missingComparison.body?.status !== 404) {
    fail("comparing an unknown reference did not return the documented 404");
  }

  const editRepository = "edit-contract-repository";
  if ((await request("/api/repos", {
    method: "POST",
    headers: {"content-type": "application/json"},
    body: JSON.stringify({name: editRepository}),
  })).response.status !== 201) {
    fail("could not create the file-edit repository");
  }
  const editBranches = await request(`/api/repos/${editRepository}/branches`);
  const editHead = editBranches.body[0]?.oid;
  const edited = await request(
    `/api/repos/${editRepository}/contents/README.md`,
    {
      method: "PUT",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({
        ref: "main",
        message: "Edit through the contents API",
        content: `# ${editRepository}\n\nSecond line.\n`,
        expected_head_oid: editHead,
      }),
    },
  );
  if (edited.response.status !== 200
      || edited.body?.ref !== "refs/heads/main"
      || !/^[0-9a-f]{40}$/.test(edited.body?.commit_oid || "")
      || edited.body.commit_oid === editHead) {
    fail("editing a file did not return a new commit");
  }
  const editedRaw = await fetch(
    `http://127.0.0.1:${port}/api/repos/${editRepository}/contents/README.md?ref=main&format=raw`,
  );
  if (await editedRaw.text() !== `# ${editRepository}\n\nSecond line.\n`) {
    fail("the edited file content was not persisted");
  }
  const editedHistory = await request(
    `/api/repos/${editRepository}/commits?ref=main`,
  );
  if (editedHistory.body?.length !== 2
      || editedHistory.body[0].message !== "Edit through the contents API"
      || editedHistory.body[0].parents?.[0] !== editHead) {
    fail("the edit did not extend the branch history");
  }
  editedHistory.body.forEach(assertCommit);
  const editedDiff = await request(
    `/api/repos/${editRepository}/compare?base=${editHead}&head=refs/heads/main`,
  );
  if (editedDiff.body?.files?.length !== 1
      || editedDiff.body.files[0].path !== "README.md"
      || !editedDiff.body.files[0].patch.includes("+Second line.")) {
    fail("the edit is not visible as a comparison diff");
  }
  const staleEdit = await request(
    `/api/repos/${editRepository}/contents/README.md`,
    {
      method: "PUT",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({
        ref: "main", message: "Stale edit", content: "overwrite\n",
        expected_head_oid: editHead,
      }),
    },
  );
  if (staleEdit.response.status !== 409 || staleEdit.body?.status !== 409) {
    fail("an edit based on a stale head was not rejected");
  }
  const unchangedEdit = await request(
    `/api/repos/${editRepository}/contents/README.md`,
    {
      method: "PUT",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({
        ref: "main", message: "No change",
        content: `# ${editRepository}\n\nSecond line.\n`,
      }),
    },
  );
  if (unchangedEdit.response.status !== 422) {
    fail("an edit without changes was not rejected");
  }
  const missingFileEdit = await request(
    `/api/repos/${editRepository}/contents/absent.md`,
    {
      method: "PUT",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({ref: "main", message: "Create", content: "x\n"}),
    },
  );
  if (missingFileEdit.response.status !== 404) {
    fail("editing a file that does not exist was not rejected");
  }
  const tagEdit = await request(
    `/api/repos/${editRepository}/contents/README.md`,
    {
      method: "PUT",
      headers: {"content-type": "application/json"},
      body: JSON.stringify({
        ref: "refs/tags/v1", message: "Edit a tag", content: "x\n",
      }),
    },
  );
  if (tagEdit.response.status !== 422) {
    fail("editing a tag was not rejected");
  }
  const editAudit = await request(`/api/repos/${editRepository}/audit`);
  if (!editAudit.body?.some((item) => item.action === "contents.update")) {
    fail("the file edit was not recorded in the audit trail");
  }

  const audit = await request("/api/repos/contract-repository/audit");
  if (audit.response.status !== 200 || !Array.isArray(audit.body)
      || !audit.body.some((item) => item.action === "issue.create")
      || !audit.body.some((item) => item.action === "issue.label")
      || !audit.body.some((item) => item.action === "pull_request.review")
      || !audit.body.every((item) => typeof item.correlation_id === "string")) {
    fail("repository audit did not expose complete event records");
  }
  console.log("REST contract test passed");
} finally {
  child.kill("SIGTERM");
}
