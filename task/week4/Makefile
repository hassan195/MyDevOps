IMAGE_NAME := app-service
TAG        ?= latest
ENV		   ?= dev


.PHONY: build test image deploy security 

build:
	@echo "Building the application..."
	python -m pip install -r requirements.txt
	python -m compileall .

security:
	@echo "Running security checks..."
	@chmod +x security_check.sh
	@./security_check.sh


test:build
	@echo "Running tests..."
	python -m unittest discover -s . -p "test_*.py"

image:
	@echo "Building Docker image with TAG=$(TAG)..."
	docker build -t $(IMAGE_NAME):$(TAG) .

deploy: image
	@echo "Deploying to ENV=$(ENV) with TAG=$(TAG)..." 
	docker rm -f $(IMAGE_NAME)-$(ENV) || true
	docker run -d --name $(IMAGE_NAME)-$(ENV) -p 8080:8080 $(IMAGE_NAME):$(TAG)