from django.urls import path
from . import views

urlpatterns = [
    path('', views.RecipeListView.as_view()),
    path('<uuid:pk>/', views.RecipeDetailView.as_view()),
    path('<uuid:pk>/save/', views.toggle_save_recipe),
    path('saved/', views.SavedRecipesView.as_view()),
    path('recommended/', views.recommended_recipes),
    path('ingredients/', views.ingredients_list),
    path('tags/', views.tags_list),
]
