.PHONY: install lint test run ci simulate validate deploy clean

install:
	pip install -r requirements.txt

lint:
	flake8 service --count --select=E9,F63,F7,F82 --show-source --statistics
	flake8 service --count --max-complexity=10 --max-line-length=127 --statistics

test:
	nosetests

run:
	flask run --host=0.0.0.0 --port=8000

ci:
	bash scripts/run-ci.sh

simulate:
	bash scripts/simulate-pipeline.sh

validate:
	bash scripts/validate-ci-cd.sh

deploy:
	bash scripts/deploy-openshift.sh

clean:
	rm -rf __pycache__ service/__pycache__ service/common/__pycache__
	rm -rf tests/__pycache__
	rm -f .coverage coverage.xml nosetests.xml
