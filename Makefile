.PHONY: diff dry-run apply test render doctor update

diff:
	chezmoi diff

dry-run:
	chezmoi apply --dry-run --verbose

apply:
	chezmoi apply

update:
	chezmoi update

test:
	./scripts/test.sh

render:
	./scripts/render.sh

doctor:
	chezmoi doctor
	chezmoi status
