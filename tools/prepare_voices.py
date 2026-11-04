"""Rebuild both user-provided voice sets; obsolete NOX takes are not restored."""
from prepare_boy_voices import main as prepare_boy
from prepare_girl_voices import main as prepare_girl

if __name__ == "__main__":
    prepare_boy()
    prepare_girl()
