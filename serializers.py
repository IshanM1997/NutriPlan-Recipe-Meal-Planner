from rest_framework import serializers
from .models import Recipe, Ingredient, RecipeIngredient, Tag


class TagSerializer(serializers.ModelSerializer):
    class Meta:
        model = Tag
        fields = ['id', 'name', 'color']


class IngredientSerializer(serializers.ModelSerializer):
    class Meta:
        model = Ingredient
        fields = ['id', 'name', 'default_unit', 'calories_per_100g',
                  'protein_per_100g', 'carbs_per_100g', 'fat_per_100g']


class RecipeIngredientSerializer(serializers.ModelSerializer):
    ingredient = IngredientSerializer(read_only=True)
    ingredient_id = serializers.PrimaryKeyRelatedField(
        queryset=Ingredient.objects.all(), write_only=True, source='ingredient'
    )

    class Meta:
        model = RecipeIngredient
        fields = ['id', 'ingredient', 'ingredient_id', 'quantity', 'unit']


class RecipeListSerializer(serializers.ModelSerializer):
    tags = TagSerializer(many=True, read_only=True)
    total_time_min = serializers.ReadOnlyField()
    is_saved = serializers.SerializerMethodField()

    class Meta:
        model = Recipe
        fields = [
            'id', 'name', 'description', 'image_url', 'meal_type',
            'difficulty', 'prep_time_min', 'cook_time_min', 'total_time_min',
            'servings', 'tags', 'suitable_for',
            'calories', 'protein_g', 'carbs_g', 'fat_g',
            'is_public', 'created_at', 'is_saved',
        ]

    def get_is_saved(self, obj):
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return obj.saved_by.filter(id=request.user.id).exists()
        return False


class RecipeDetailSerializer(RecipeListSerializer):
    recipe_ingredients = RecipeIngredientSerializer(many=True, read_only=True)

    class Meta(RecipeListSerializer.Meta):
        fields = RecipeListSerializer.Meta.fields + ['instructions', 'recipe_ingredients']
