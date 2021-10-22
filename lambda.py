people = [
    {"name": "Harry", "house": "Gryffindor"},
    {"name": "Cho", "house": "Ravenclaw"},
    {"name": "Draco","house": "Slytherin"},
    {"name": "Hermione", "house":"Gryffindor"}
]
#sort using function below
def f(person):
    return person["name"]
people.sort(key = f)
# Use lambda as a complete function above 
people.sort(key=lambda person: person["name"])
print(people)
