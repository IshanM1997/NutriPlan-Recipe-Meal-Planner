from rest_framework import generics, filters
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.db.models import Q
from .models import Recipe, Ingredient, Tag
from .serializers import RecipeListSerializer, RecipeDetailSerializer, IngredientSerializer, TagSerializer


class RecipeListView(generics.ListAPIView):
    serializer_class = RecipeListSerializer
    permission_classes = [IsAuthenticated]
    filter_backends = [filters.SearchFilter]
    search_fields = ['name', 'description', 'tags__name']

    def get_queryset(self):
        qs = Recipe.objects.filter(is_public=True).prefetch_related('tags', 'saved_by')
        meal_type = self.request.query_params.get('meal_type')
        goal = self.request.query_params.get('goal')
        max_cal = self.request.query_params.get('max_calories')
        if meal_type:
            qs = qs.filter(Q(meal_type=meal_type) | Q(meal_type='any'))
        if goal:
            qs = qs.filter(Q(suitable_for=goal) | Q(suitable_for='any'))
        if max_cal:
            qs = qs.filter(calories__lte=float(max_cal))
        return qs

    def get_serializer_context(self):
        return {'request': self.request}


class RecipeDetailView(generics.RetrieveAPIView):
    queryset = Recipe.objects.prefetch_related('tags', 'recipe_ingredients__ingredient', 'saved_by')
    serializer_class = RecipeDetailSerializer
    permission_classes = [IsAuthenticated]

    def get_serializer_context(self):
        return {'request': self.request}


class SavedRecipesView(generics.ListAPIView):
    serializer_class = RecipeListSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return self.request.user.saved_recipes.all()

    def get_serializer_context(self):
        return {'request': self.request}


@api_view(['POST', 'DELETE'])
@permission_classes([IsAuthenticated])
def toggle_save_recipe(request, pk):
    try:
        recipe = Recipe.objects.get(pk=pk)
    except Recipe.DoesNotExist:
        return Response({'detail': 'Not found'}, status=404)
    if request.method == 'POST':
        recipe.saved_by.add(request.user)
        return Response({'saved': True})
    recipe.saved_by.remove(request.user)
    return Response({'saved': False})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def ingredients_list(request):
    qs = Ingredient.objects.all()
    q = request.query_params.get('q')
    if q:
        qs = qs.filter(name__icontains=q)
    return Response(IngredientSerializer(qs[:50], many=True).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def tags_list(request):
    return Response(TagSerializer(Tag.objects.all(), many=True).data)


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def recommended_recipes(request):
    """Return recipes matching user's latest BMI goal and calorie budget"""
    from bmi.models import BMIRecord
    record = BMIRecord.objects.filter(user=request.user).first()

    meal_type = request.query_params.get('meal_type', 'any')
    if record:
        split = {
            'breakfast': record.target_calories * 0.25,
            'morning_snack': record.target_calories * 0.10,
            'lunch': record.target_calories * 0.35,
            'afternoon_snack': record.target_calories * 0.10,
            'dinner': record.target_calories * 0.20,
            'any': record.target_calories * 0.35,
        }
        max_cal = split.get(meal_type, record.target_calories * 0.35)
        goal = record.goal
    else:
        max_cal = 700
        goal = 'any'

    qs = Recipe.objects.filter(
        Q(suitable_for=goal) | Q(suitable_for='any'),
        calories__lte=max_cal,
    )
    if meal_type != 'any':
        qs = qs.filter(Q(meal_type=meal_type) | Q(meal_type='any'))

    return Response(RecipeListSerializer(
        qs.order_by('?')[:12], many=True, context={'request': request}
    ).data)
