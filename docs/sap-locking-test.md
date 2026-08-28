# SAP multi-application-server locking test

This test is an environment check and requires two HitHub ICF endpoints that
route to different SAP application servers. Both servers must use the same SAP
database and enqueue service.

## Preconditions

1. Activate the `ZHI_REPOSITORY` table and create/activate lock object
   `EZHI_REPO` on `ZHI_REPOSITORY-REPOSITORY_ID`. The generated function
   modules must be named `ENQUEUE_EZHI_REPO` and `DEQUEUE_EZHI_REPO`.
2. Deploy the same HitHub transport to both application servers and configure
   the service routes through the Web Dispatcher (or equivalent gateway).
3. Select one repository and two distinct owners, `lock-test-a` and
   `lock-test-b`.

## Procedure

1. From a session pinned to application server A, start a push or merge for
   the selected repository and pause it after lock acquisition (a debugger
   breakpoint in `ZCL_HITHUB_SAP_REPO_LOCK=>TRY_ENQUEUE` is sufficient).
2. While that request is paused, start a second push or merge for the same
   repository through a session pinned to application server B.
3. Verify that the second request waits only for the configured timeout and
   then fails without changing refs or writing a partial result.
4. Resume the first request, verify it commits once, and verify that server B
   can acquire the lock after server A releases it.
5. Repeat with the first request terminated by the work-process timeout. Verify
   in `SM12` that the lock is released with the owner session and that a new
   request can proceed.

The test passes only when the second server observes the first server's lock;
two successful acquisitions while the first request is paused are a failure.
