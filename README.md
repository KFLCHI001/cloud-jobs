# cloud-jobs

A generic runner for heavy work: renders, ffmpeg, Python and Node scripts. It runs them on free GitHub
Actions runners so a local PC stays free.

This repo is public and holds runner code only. No footage, audio, images, project content, keys or `.env`
values are ever committed here. Job files travel through a private Cloudflare R2 bucket.

## How it works

1. The caller packs the files a job needs into `bundle.tar.gz` (with a `job.sh` at its top level) and uploads
   it to R2 at `jobs/<job>/bundle.tar.gz`. A bundle over 280 MB is split into `bundle.tar.gz.000`,
   `.001`, ... with a `bundle.parts` text file holding the part count.
2. The caller dispatches the `job` workflow with three inputs:
   - `job`: the R2 prefix, for example `my-project/render-20261025-1`. It must match `^[a-z0-9][a-z0-9._/-]{2,120}$`.
   - `tasks`: a JSON array of task names, for example `["part1","part3"]`. Each matches `^[a-zA-Z0-9._-]{1,40}$`.
     One runner starts per task, all at once.
   - `profile`: `hyperframes`, `ffmpeg`, `python`, `node` or `trigger-test`.
3. Each runner downloads the bundle, extracts it to `work/` and runs `bash job.sh <task>` from inside
   `work/`.
4. The runner uploads results back to R2 and stops.

```
gh workflow run job.yml -R KFLCHI001/cloud-jobs -f job=my-project/render-20261025-1 -f 'tasks=["part1","part3"]' -f profile=hyperframes
```

`trigger-test` validates the inputs and prints OK. It starts no runner, reads no secret and touches no R2.

## The bundle contract

`job.sh <task>` runs with its working directory at the bundle root. It writes every result under
`out/<task>/`. A non-zero exit fails the task. Tasks run on separate machines and cannot see each other.

The job runs without the R2 credentials in its environment.

Results land in R2:

| Object | What it holds |
| --- | --- |
| `jobs/<job>/out/<task>/...` | the files `job.sh` wrote under `out/<task>/` |
| `jobs/<job>/out/<task>/MANIFEST.txt` | one `path<TAB>bytes` line per output file, uploaded last |
| `jobs/<job>/logs/<task>.log` | everything `job.sh` printed |
| `jobs/<job>/status/<task>.json` | `{"task": "...", "exit": 0, "seconds": 123}` |

A bucket lifecycle rule deletes objects after 14 days.

`examples/hyperframes/job.sh` is a sample for the `hyperframes` profile.

## Privacy model

- The repo is public, so Actions logs are public. The workflow sends `job.sh` output to a file and prints one
  line per task (task, exit code, seconds, file count, bytes). No file names, no bundle contents. The full log
  is uploaded to R2.
- No `actions/upload-artifact`. Nothing from a job is stored on GitHub.
- The workflow runs only on `workflow_dispatch`: no push, pull request, pull request target or schedule
  trigger. Forks cannot start it, and GitHub does not give secrets to workflows run from forks.
- Every job checks `github.actor == 'KFLCHI001'`, so a collaborator or a leaked token for another account
  cannot use the secrets.
- Repo secrets are `R2_ACCOUNT_ID`, `R2_ACCESS_KEY_ID` and `R2_SECRET_ACCESS_KEY`. The key pair is an R2 API
  token limited to the one bucket. Only the steps that talk to R2 see them.
- The `job` and `tasks` inputs appear on the public run page. Use neutral names.
- Default workflow permissions are read-only. Only GitHub-owned actions are allowed, pinned by commit.

## Cost

A public repo gets standard Linux runners for free. They do not use the account's included minutes or its
Actions budget. Do not switch the repo to private, or use larger or macOS runners, without checking the cost.
Each job can run at most 180 minutes.
