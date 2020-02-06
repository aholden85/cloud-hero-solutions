# cloud-hero-solutions
This is a workspace for me to store CLI/API-implemented solutions to GCP Cloud Hero challenges. Ideally, you'd run these from the Cloud Shell within the [Google Cloud Console][gcp-console]. Currently this only contains details on the first two exercises, `GSP501` and `GSP502`, and will grow organically.

The layout for this document is to provide context around the simple script file that contains only the config required to complete the labs. It is comprised of a mix of instructions from the Qwiklabs exercises themselves, with the config to complete those instructions in subsequent code blocks.

# Setup
Let's define some variables that we'll use in our solutions.
```
export PROJECT_ID=$(gcloud info --format='value(config.project)')
export USER_EMAIL=$(gcloud info --format='value(config.account)')
export USER_NAME=${USER_EMAIL%@*}
```

# [GSP501] Cloud Hero: Into the cloud
### Task 1. Create a storage bucket
Create a Cloud Storage bucket called `cloud-hero-[PROJECT_ID]` using the GCP Console or CLI.
```
export BUCKET_NAME="cloud-hero-$PROJECT_ID"
gsutil mb gs://$BUCKET_NAME/
```
Make the bucket publicly readable.
```
gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME
```
### Task 2. Create a Cloud Pub/Sub topic
Create a Cloud Pub/Sub topic called `cloud-hero-topic`.
```
gcloud pubsub topics create cloud-hero-topic
```

# [GSP502] Cloud Hero: Building blocks
### Task 1. Deploy a Cloud Function
1. Download the function files from GCS:
```
wget https://storage.googleapis.com/cloudhero-content/pubSubListener/index.js
wget https://storage.googleapis.com/cloudhero-content/pubSubListener/package.json
```
2. Edit `index.js` and replace `https://www.example.com` with `https://us-central1-cloudhero-test.cloudfunctions.net/cloudFunctionChallenge_verifyCallback`
```
sed -i 's,www.example.com,us-central1-cloudhero-test.cloudfunctions.net/cloudFunctionChallenge_verifyCallback,g' index.js
```
3. Deploy a function called `pubSubListener` running this code that is triggered by messages being published to the `cloud-hero-topic` Cloud Pub/Sub topic. Make sure that you specify the correct entry-point function name.
```
mkdir function-deploy
mv index.js function-deploy
mv package.json function-deploy

gcloud functions deploy pubSubListener --allow-unauthenticated --trigger-topic=cloud-hero-topic --runtime=nodejs8 --source=function-deploy --entry-point=pubSubListener
```
### Task 2. Create a Google Source Repository for continuous integration
1. Set up a new git repo in Source Repositories called cloudhero-challenge.
```
gcloud source repos create cloudhero-challenge
```
2. Clone the repo https://github.com/GoogleCloudPlatform/getting-started-python.git to your Lab VM or Cloud Shell.
```
git clone https://github.com/GoogleCloudPlatform/getting-started-python.git
```
3. Change into the root of that directory.
```
cd getting-started-python
```
4. Configure a git username and email using the lab username so that you can commit and push updates:
```
git config --global user.email $USER_EMAIL
git config --global user.name $USER_NAME
```
5. Add `https://source.developers.google.com/p/$PROJECT_ID/r/cloudhero-challenge` as a remote repository.
```
git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/cloudhero-challenge
```
6. Once you have added the remote repository you must issue a `git push --all` command from the root of the cloned directory to push the initial version to your Google Source Repository:
```
git push --all google
```
7. If you are successful, you will see the project structure when you open the repository with the GCP Console:
 
### Task 3. Create an automated build in Container Registry
##### Create a storage bucket for Cloud Build
1. Create a Cloud Storage bucket called `cloud-hero-[PROJECT_ID]` using the GCP Console or CLI.
```
export BUCKET_NAME="cloud-hero-$PROJECT_ID"
gsutil mb gs://$BUCKET_NAME/
```
2. Make the bucket publicly readable.
```
gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME
```
##### Configure the sample application for your project
1. In your local copy of the demo application source repo, edit the file `optional-kubernetes-engine/config.py` and change the placeholder `CLOUD_STORAGE_BUCKET = 'your-bucket-name'` to your bucket name `CLOUD_STORAGE_BUCKET = 'cloud-hero-[PROJECT_ID]'`. Remember to substitute your project ID for `[PROJECT_ID]` in this example.
```
sed -i 's,your-bucket-name,$BUCKET_NAME,g' optional-kubernetes-engine/config.py
```
2. Change the line `PROJECT_ID = 'your-project-id'` to `PROJECT_ID=[PROJECT_ID]`
```
sed -i 's,your-project-id,$PROJECT_ID,g' optional-kubernetes-engine/config.py
```
##### Create a build trigger
1. In the GCP Console create a Cloud Build trigger that will trigger on pushes to the master branch of your Cloud Source Repository called `cloudhero-challenge`
2. Set the trigger's Dockerfile path to `/optional-kubernetes-engine`
3. Set the trigger's image name to `gcr.io/$PROJECT_ID/bookshelf:$COMMIT_SHA`
```
gcloud beta builds triggers create cloud-source-repositories --repo="cloudhero-challenge" --branch-pattern="master" --dockerfile="Dockerfile" --dockerfile-dir="/optional-kubernetes-engine" --dockerfile-image="gcr.io/$PROJECT_ID/bookshelf:$COMMIT_SHA"
```
##### Trigger a build
1. Commit all file changes made to your local copy of the repo and then push your repo changes:
```
git add .
git commit -m "Updating project with changes"
git push google master
```

[//]: # (These are reference links used in the body of this note and get stripped out when the markdown processor does its job. There is no need to format nicely because it shouldn't be seen. Thanks SO - http://stackoverflow.com/questions/4823468/store-comments-in-markdown-syntax)
   [gcp-console]: <https://console.cloud.google.com/>
