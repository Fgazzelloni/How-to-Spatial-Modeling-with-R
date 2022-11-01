# Step to creation:

# create a new project on a new directory
quarto book project
# if you have a github repo then move the files
# in the other project folder which is empty


# add files
# the _quarto.yml top file looks like this:
project:
  type: book
# type on terminal
quarto preview
# it creates a folder
_book
# and some other folders, specifics for chapters' cache/files
# something like, the name of the chapter_
_cache
_files

# publish your book on github pages
# change the _quarto.yml file into:
project:
  type: website
output-dir: docs
# add a .nojekyll file ...(terminal)
touch .nojekyll
# then type
quarto render
# some issues might arise if more than one
# calculation is made inside a single cunck
# split the cuncks!
# quarto render creates a folder
docs

# check the index.html file




