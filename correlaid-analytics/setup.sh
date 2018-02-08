
# virtual environment for python
virtualenv venv 
source venv/bin/activate 

# install python requirements locally in venv
pip install -r requirements.txt

# install npm serverless module
# serverless allows you to deploy a aws lambda microservice
# TODO: make sure you have npm installed
npm install serverless

# steps needed to deploy requirements later
npm init
npm install --save serverless-python-requirements



