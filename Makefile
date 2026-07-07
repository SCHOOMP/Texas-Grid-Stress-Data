.PHONY: up down psql logs clean

up:
	docker compose up -d --build

down:
	docker compose down

psql:
	docker compose exec db psql -U grid -d grid_observatory

logs:
	docker compose logs -f

clean:
	docker compose down -v