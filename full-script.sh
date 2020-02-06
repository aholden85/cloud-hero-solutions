# SETUP
export PROJECT_ID=$(gcloud info --format='value(config.project)')
export USER_EMAIL=$(gcloud info --format='value(config.account)')
export USER_NAME=${USER_EMAIL%@*}

export BUCKET_NAME="cloud-hero-$PROJECT_ID"



# Ex1 GSP501
gsutil mb gs://cloud-hero-$PROJECT_ID/
gsutil iam ch allUsers:objectViewer gs://$BUCKET_NAME
gcloud pubsub topics create cloud-hero-topic



# Ex2 GSP502
wget https://storage.googleapis.com/cloudhero-content/pubSubListener/index.js
wget https://storage.googleapis.com/cloudhero-content/pubSubListener/package.json
sed -i 's,www.example.com,us-central1-cloudhero-test.cloudfunctions.net/cloudFunctionChallenge_verifyCallback,g' index.js

mkdir function-deploy
mv index.js function-deploy
mv package.json function-deploy

git config --global user.email $USER_EMAIL
git config --global user.name $USER_NAME
git clone https://github.com/GoogleCloudPlatform/getting-started-python.git

gcloud functions deploy pubSubListener --allow-unauthenticated --trigger-topic=cloud-hero-topic --runtime=nodejs8 --source=function-deploy --entry-point=pubSubListener
gcloud source repos create cloudhero-challenge

cd getting-started-python
git remote add google https://source.developers.google.com/p/$PROJECT_ID/r/cloudhero-challenge
git push --all google

sed -i 's,your-bucket-name,$BUCKET_NAME,g' optional-kubernetes-engine/config.py
sed -i 's,your-project-id,$PROJECT_ID,g' optional-kubernetes-engine/config.py

gcloud beta builds triggers create cloud-source-repositories --repo="cloudhero-challenge" --branch-pattern="master" --dockerfile="Dockerfile" --dockerfile-dir="/optional-kubernetes-engine" --dockerfile-image="gcr.io/$PROJECT_ID/bookshelf:$COMMIT_SHA"

git add .
git commit -m "Updating project with changes"
git push google master
