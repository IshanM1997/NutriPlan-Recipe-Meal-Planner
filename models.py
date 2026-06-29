from django.db import models
from django.conf import settings
import uuid


class Ingredient(models.Model):
    UNIT_CHOICES = [
        ('g', 'Grams'), ('kg', 'Kilograms'),
        ('ml', 'Millilitres'), ('l', 'Litres'),
        ('cup', 'Cup'), ('tbsp', 'Tablespoon'), ('tsp', 'Teaspoon'),
        ('piece', 'Piece'), ('slice', 'Slice'),
    ]
    name = models.CharField(max_length=120, unique=True)
    default_unit = models.CharField(max_length=10, choices=UNIT_CHOICES, default='g')
    calories_per_100g = models.FloatField(default=0)
    protein_per_100g = models.FloatField(default=0)
    carbs_per_100g = models.FloatField(default=0)
    fat_per_100g = models.FloatField(default=0)

    class Meta:
        db_table = 'ingredients'
        ordering = ['name']

    def __str__(self):
        return self.name


class Tag(models.Model):
    name = models.CharField(max_length=50, unique=True)
    color = models.CharField(max_length=7, default='#4CAF50')

    class Meta:
        db_table = 'tags'

    def __str__(self):
        return self.name


class Recipe(models.Model):
    MEAL_TYPE_CHOICES = [
        ('breakfast', 'Breakfast'),
        ('morning_snack', 'Morning Snack'),
        ('lunch', 'Lunch'),
        ('afternoon_snack', 'Afternoon Snack'),
        ('dinner', 'Dinner'),
        ('any', 'Any'),
    ]
    DIFFICULTY_CHOICES = [('easy', 'Easy'), ('medium', 'Medium'), ('hard', 'Hard')]
    GOAL_CHOICES = [('lose', 'Weight Loss'), ('maintain', 'Maintenance'), ('gain', 'Muscle Gain'), ('any', 'Any')]

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True)
    image_url = models.URLField(max_length=500, blank=True)
    meal_type = models.CharField(max_length=20, choices=MEAL_TYPE_CHOICES, default='any')
    difficulty = models.CharField(max_length=10, choices=DIFFICULTY_CHOICES, default='easy')
    prep_time_min = models.IntegerField(default=10)
    cook_time_min = models.IntegerField(default=20)
    servings = models.IntegerField(default=2)
    instructions = models.TextField(blank=True)
    tags = models.ManyToManyField(Tag, blank=True, related_name='recipes')
    suitable_for = models.CharField(max_length=10, choices=GOAL_CHOICES, default='any')

    # Nutrition per serving (auto-computed or manual)
    calories = models.FloatField(default=0)
    protein_g = models.FloatField(default=0)
    carbs_g = models.FloatField(default=0)
    fat_g = models.FloatField(default=0)

    is_public = models.BooleanField(default=True)
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name='created_recipes'
    )
    saved_by = models.ManyToManyField(
        settings.AUTH_USER_MODEL, blank=True, related_name='saved_recipes'
    )
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'recipes'
        ordering = ['name']

    def __str__(self):
        return self.name

    @property
    def total_time_min(self):
        return self.prep_time_min + self.cook_time_min


class RecipeIngredient(models.Model):
    """Through model for Recipe ↔ Ingredient with quantity and unit"""
    UNIT_CHOICES = [
        ('g', 'Grams'), ('kg', 'Kilograms'),
        ('ml', 'Millilitres'), ('l', 'Litres'),
        ('cup', 'Cup'), ('tbsp', 'Tablespoon'), ('tsp', 'Teaspoon'),
        ('piece', 'Piece'), ('slice', 'Slice'),
    ]
    recipe = models.ForeignKey(Recipe, on_delete=models.CASCADE, related_name='recipe_ingredients')
    ingredient = models.ForeignKey(Ingredient, on_delete=models.CASCADE)
    quantity = models.FloatField()
    unit = models.CharField(max_length=10, choices=UNIT_CHOICES, default='g')

    class Meta:
        db_table = 'recipe_ingredients'
        unique_together = ('recipe', 'ingredient')

    def __str__(self):
        return f"{self.quantity}{self.unit} {self.ingredient.name}"
