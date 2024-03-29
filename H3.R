# Cargar datos desde un archivo CSV
datos <- read.csv("train.csv", header = TRUE, encoding = "UTF-8")

View(datos$MiscVal)

summary(datos)

View(datos)

datos_para_clustering <- datos[, c("LotFrontage", "LotArea", "OverallQual", "OverallCond", "YearBuilt",
                                   "YearRemodAdd", "TotalBsmtSF", "BsmtFullBath", "BsmtHalfBath", "FullBath", "HalfBath",
                                   "TotRmsAbvGrd", "Fireplaces", "GarageYrBlt", "GarageCars", "GarageArea",
                                   "PoolArea", "MiscVal", "MoSold", "YrSold", "SalePrice")]

datos_para_clustering <- na.omit(datos_para_clustering) 








normalized_data <- scale(datos_para_clustering)

View(normalized_data)

#Obtener cantidad de clusteres
set.seed(123)
k_values <- 1:10
iner <- numeric(length(k_values))

for (k in k_values) {
  model <- kmeans(normalized_data, centers = k)
  iner[k] <- model$tot.withinss
}

plot(k_values, iner, type = "b", main = "Método del Codo", xlab = "Número de Clústeres (k)", ylab = "Inercia")
abline(v = which.min(diff(iner) > 10) + 1, col = "red", lty = 2)

#Al obtener la cantidad de clusters, realizamos K-Means para encontrar los grupos.

set.seed(123)
num_clusters <- 2  # Número de clústeres determinado anteriormente

# Aplicar el algoritmo de k-means
kmeans_model <- kmeans(normalized_data, centers = num_clusters)

# Añadir las etiquetas de clúster al conjunto de datos
normalized_data$kmeans_cluster <- as.factor(kmeans_model$cluster)

# Visualizar el resultado del clustering
table(normalized_data$kmeans_cluster)

#
# División de grupos train y test para modelos de regresión lineal
#

porcentaje <- 0.52 #Porcentaje con el que se calcularán los grupos de train y test.
datos_cuantitativos<- datos_para_clustering
corte <- sample(nrow(datos_cuantitativos),nrow(datos_cuantitativos)*porcentaje)
train<-datos_cuantitativos[corte,] #Corte para el grupo entrenamiento
test<-datos_cuantitativos[-corte,] #Corte para el grupo prueba

head(train)
head(test)

#Creación del modelo de regresión lineal.
single_linear_model<- lm(SalePrice~OverallQual, data = train) #Modelo lineal singular para SalePrice y OverallQual
summary(single_linear_model)

#Análisis de residuos

head(single_linear_model$residuals)

boxplot(single_linear_model$residuals)

# Análisis de predicción en conjunto prueba.

predSLM<-predict(single_linear_model, newdata = test)
head(predSLM)
length(predSLM)

# Gráfico del Modelo de Regresión Lineal Simple

library(ggplot2)
ggplot(data = train, mapping = aes(x = OverallQual, y = SalePrice)) +
  geom_point(color = "lightgreen", size = 2) +
  geom_smooth(method = "lm", se = TRUE, color = "blue") +
  labs(title = "Calidad Promedio del Material x Precio de Venta", x = "Calidad Promedio", y = "Precio de Venta") +
  theme_bw() + theme(plot.title = element_text(hjust = 0.5))


#Modelo lineal múltiple para SalePrice.
multiple_linear_model<-lm(SalePrice~.,data = train)

summary(multiple_linear_model)


# Analisis de la correlacción

var_independients <- train[, -which(names(train) == "SalePrice")]

correlation_matrix <- cor(var_independients)

print(correlation_matrix)







#HOJA DE TRABAJO 4

# Cargar datos desde un archivo CSV
datos <- read.csv("train.csv", header = TRUE, encoding = "UTF-8")
datos <- datos[, -1]

View(datos)

porcentaje4 <- 0.70
trainRowsNumber<-sample(1:nrow(datos),porcentaje4*nrow(datos))
train<-datos[trainRowsNumber,]
test<-datos[-trainRowsNumber,]

data_tree <- datos
summary(data_tree)
library(rpart)

#Instalar paquetes con rplot
#install.packages("rpart.plot")
library(rpart.plot)

#Crear nuestro modelo_arbol
modelo_arbol <- rpart(SalePrice~.,data=data_tree)

summary(modelo_arbol)

#Mostrar el arbol con la data de SalePrice
rpart.plot(modelo_arbol, digits = 3, fallen.leaves = TRUE)

#Predicción y análisis del resultado.

modelo_train <- rpart(SalePrice~.,data=train)
rpart.plot(modelo_train, digits = 3, fallen.leaves = TRUE)

prediccion <- predict(modelo_arbol, newdata = test)

head(prediccion)

mse <- mean((test$SalePrice - prediccion)^2)
print(paste("Error Cuadrático Medio (MSE):", mse))

r_cuadrado <- 1 - mse / var(test$SalePrice)
print(paste("Coeficiente de Determinación (R^2):", r_cuadrado))

#Añadir 3 modelos más:

# Crear una lista de modelos con diferentes profundidades
modelos <- list()
for (depth in 1:3) {
  modelos[[depth]] <- rpart(SalePrice~., data = data_tree, control = rpart.control(maxdepth = depth))
}
# Evaluar los modelos
for (i in 1:length(modelos)) {
  predicciones <- predict(modelos[[i]], newdata = test)
  mse <- mean((test$SalePrice - predicciones)^2)
  correlacion <- cor(test$SalePrice, predicciones)
  print(paste("Profundidad:", i, "MSE:", mse, "Coeficiente de correlación:", correlacion))
}

#Inciso 6. Clasificar las casas en Económicas, Intermedias y Caras.

# Definir cuartiles
cuartiles <- quantile(datos$SalePrice, probs = c(0.25, 0.5, 0.75))

# Crear variable respuesta
datos$Clasificacion <- cut(datos$SalePrice, breaks = c(0, cuartiles[2], cuartiles[3], max(datos$SalePrice)), labels = c("Económicas", "Intermedias", "Caras"))

View(datos)

# Contar el número de casas en cada categoría
num_casas <- table(datos$Clasificacion)
print(num_casas)

#Añadir Clasificacion a los conjuntos train y test.

trainRowsNumber<-sample(1:nrow(datos),porcentaje4*nrow(datos))
train<-datos[trainRowsNumber,]
test<-datos[-trainRowsNumber,]

# Inciso 7 - Creación del árbol

# Crear modelo de árbol de clasificación

modelo_arbol_clasificacion <- rpart(Clasificacion ~ . - SalePrice, data = datos, method = "class")
# Visualizar el árbol
rpart.plot(modelo_arbol_clasificacion, digits = 3, fallen.leaves = TRUE)

# Inciso 8.
# Predecir con el conjunto de prueba
predicciones_clasificacion <- predict(modelo_arbol_clasificacion, newdata = test, type = "class")

head(predicciones_clasificacion)

# Calcular la precisión
precision <- sum(predicciones_clasificacion == test$Clasificacion) / length(test$Clasificacion)
print(paste("Precisión del árbol de clasificación:", precision))


# Inciso 9
# Analisis de eficiencia del algoritmo con matriz de confusión

#install.packages("caret")
library(caret)

confusion_matrix <- confusionMatrix(predicciones_clasificacion, test$Clasificacion)
print("Matriz de Confusión:")
print(confusion_matrix)

# Mostrar la precisión global y por clase
print(paste("Precisión Global:", confusion_matrix$overall["Accuracy"]))

# Mostrar la precisión global y por clase
precision_global <- confusion_matrix$overall["Accuracy"]
print(paste("Precisión Global:", ifelse(!is.na(precision_global), precision_global, "No disponible")))
print("Precisión por Clase:")
balanced_accuracy <- confusion_matrix$byClass["Balanced Accuracy"]
print(paste("Precisión Balanceada:", ifelse(!is.na(balanced_accuracy), balanced_accuracy, "No disponible")))

# Mostrar errores más comunes
sensibilidad <- confusion_matrix$byClass["Sens"]
print("Sensibilidad (Errores más comunes):")
print(ifelse(!is.na(sensibilidad), sensibilidad, "No disponible"))
especificidad <- confusion_matrix$byClass["Spec"]
print("Especificidad (Errores menos comunes):")
print(ifelse(!is.na(especificidad), especificidad, "No disponible"))


# Inciso 10
# Entrenar modelo con validación cruzada


# Definir el control de la validación cruzada
ctrl <- trainControl(method = "cv", number = 10)  # 10-fold cross-validation


datos_imputados <- datos
for (col in colnames(datos)) {
  if (any(is.na(datos[[col]]))) {
    datos_imputados[[col]][is.na(datos[[col]])] <- mean(datos[[col]], na.rm = TRUE)
  }
}

print("Valores faltantes después de la imputación:")
print(colSums(is.na(datos_imputados)))

datos_imputados <- datos_imputados[, colSums(is.na(datos_imputados)) == 0]


# Entrenar el modelo con validación cruzada
modelo_cruzado <- train(Clasificacion ~ . - SalePrice, data = datos_imputados, method = "rpart", trControl = ctrl)

# Mostrar el resumen del modelo cruzado
print(modelo_cruzado)

# Realizar predicciones con el modelo cruzado en el conjunto de prueba
predicciones_cruzadas <- predict(modelo_cruzado, newdata = test)

# Calcular la precisión con el modelo cruzado
precision_cruzada <- sum(predicciones_cruzadas == test$Clasificacion) / length(test$Clasificacion)
print(paste("Precisión con validación cruzada:", precision_cruzada))



# Inciso 11
# Añadir 3 modelos más con diferentes profundidades al árbol de clasificación
for (depth in c(4,8,12)) {
  modelo <- rpart(Clasificacion ~ . - SalePrice, data = datos, method = "class", control = rpart.control(maxdepth = depth))
  # Visualizar el árbol
  rpart.plot(modelo, digits = depth, fallen.leaves = TRUE)
  
  # Realizar predicciones con el conjunto de prueba
  predicciones_clasificacion <- predict(modelo, newdata = test, type = "class")
  
  # Calcular la precisión
  precision <- sum(predicciones_clasificacion == test$Clasificacion) / length(test$Clasificacion)
  print(paste("Profundidad:", depth, "Precisión del árbol de clasificación:", precision))
}



# Inciso 12
# Instalar y cargar el paquete randomForest
# install.packages("randomForest")
library(randomForest)


datos_imputados <- datos
for (col in colnames(datos)) {
  if (any(is.na(datos[[col]]))) {
    datos_imputados[[col]][is.na(datos[[col]])] <- mean(datos[[col]], na.rm = TRUE)
  }
}

print("Valores faltantes después de la imputación:")
print(colSums(is.na(datos_imputados)))

datos_imputados <- datos_imputados[, colSums(is.na(datos_imputados)) == 0]
# Ajustar modelo Random Forest con datos imputados
modelo_rf <- randomForest(Clasificacion ~ . - SalePrice, data = datos_imputados)
print(modelo_rf)

# Asegurar niveles de factor consistentes
test$Clasificacion <- factor(test$Clasificacion, levels = levels(datos_imputados$Clasificacion))

# Realizar predicciones con el conjunto de prueba
predicciones_rf <- predict(modelo_rf, newdata = test, type = "response")

# Calcular la precisión con el modelo Random Forest
precision_rf <- sum(predicciones_rf == test$Clasificacion, na.rm = TRUE) / length(test$Clasificacion)
print(paste("Precisión con Random Forest:", precision_rf))


#HOJA DE TRABAJO 5
# Cargar el paquete caret

datos <- read.csv("train.csv", header = TRUE, encoding = "UTF-8")
datos <- datos[, -1]

datos_imputados <- datos
for (col in colnames(datos)) {
  if (any(is.na(datos[[col]]))) {
    datos_imputados[[col]][is.na(datos[[col]])] <- mean(datos[[col]], na.rm = TRUE)
  }
}

print("Valores faltantes después de la imputación:")
print(colSums(is.na(datos_imputados)))

datos_imputados <- datos_imputados[, colSums(is.na(datos_imputados)) == 0]

set.seed(123) # Para reproducibilidad
porcentaje_entrenamiento <- 0.7
indices_entrenamiento <- sample(1:nrow(datos), porcentaje_entrenamiento * nrow(datos))
train <- datos[indices_entrenamiento, ]
test <- datos[-indices_entrenamiento, ]

install.packages("caret")
library(ggplot2)
library(lattice)
library(caret)
library(e1071)

# Inciso 2)

modelo_nb <- naiveBayes(SalePrice ~ ., data = train)

# Mostrar el resumen del modelo
print(modelo_nb)

# Realizar predicciones en el conjunto de prueba
predicciones <- predict(modelo_nb, test)

# Explorar las predicciones
print(predicciones)


# Calcular la precisión del modelo
precision <- sum(predicciones == test$SalePrice) / length(predicciones) * 100

# Mostrar la precisión
print(precision)

datos_imputados$SalePrice <- as.numeric(as.character(datos_imputados$SalePrice))
class(datos_imputados$SalePrice)

predicciones <- as.numeric(as.character(predicciones))


r_squared <- 1 - mean((datos_imputados$SalePrice - predicciones)^2) / var(datos_imputados$SalePrice)
print(r_squared)


# Calcular el error cuadrático medio (MSE)
mse <- mean((predicciones - datos_imputados$SalePrice)^2)

print(mse)

#Inciso 5
# Cargar el paquete necesario
library(e1071)

# Definir cuartiles
cuartiles <- quantile(datos$SalePrice, probs = c(0.25, 0.5, 0.75))

# Crear variable respuesta
datos$Clasificacion <- cut(datos$SalePrice, breaks = c(0, cuartiles[2], cuartiles[3], max(datos$SalePrice)), labels = c("Económicas", "Intermedias", "Caras"))

# Contar el número de casas en cada categoría
num_casas <- table(datos$Clasificacion)
print(num_casas)

# 1. Preparar los datos
# Asegúrate de que la variable de respuesta esté definida y sea de tipo factor
datos$Clasificacion <- factor(datos$Clasificacion)

View(datos)

# 2. Dividir los datos en conjuntos de entrenamiento y prueba (si aún no están divididos)
set.seed(123) # Para reproducibilidad
porcentaje_entrenamiento <- 0.7
indices_entrenamiento <- sample(1:nrow(datos), porcentaje_entrenamiento * nrow(datos))
train <- datos[indices_entrenamiento, ]
test <- datos[-indices_entrenamiento, ]

# 3. Entrenar el modelo de clasificación Naive Bayes
modelo_nbClasificacion <- naiveBayes(Clasificacion ~ . - SalePrice, data = train)

# 4. Realizar predicciones utilizando el conjunto de prueba
predicciones_nbClasificacion <- predict(modelo_nbClasificacion, newdata = test)

View(test)

#Inciso 6
# Calcular la precisión del modelo Naive Bayes en el conjunto de prueba

precision_nbClasificacion <- mean(predicciones_nbClasificacion == test$Clasificacion)
print(paste("Precisión del modelo Naive Bayes:", precision_nbClasificacion))

#Inciso 7

library(caret)

# Crear matriz de confusión
confusion_matrix <- confusionMatrix(predicciones_nbClasificacion, test$Clasificacion)

# Mostrar matriz de confusión
print(confusion_matrix)

#Inciso 9

# Definir el esquema de partición para la validación cruzada
control <- trainControl(method = "cv", number = 10)  # 5-fold cross-validation

datos_imputados <- datos
for (col in colnames(datos)) {
  if (any(is.na(datos[[col]]))) {
    datos_imputados[[col]][is.na(datos[[col]])] <- mean(datos[[col]], na.rm = TRUE)
  }
}

print("Valores faltantes después de la imputación:")
print(colSums(is.na(datos_imputados)))

datos_imputados <- datos_imputados[, colSums(is.na(datos_imputados)) == 0]

porcentaje_entrenamiento <- 0.7
indices_entrenamiento <- sample(1:nrow(datos_imputados), porcentaje_entrenamiento * nrow(datos_imputados))
train_imputado <- datos_imputados[indices_entrenamiento, ]
test_imputado <- datos_imputados[-indices_entrenamiento, ]

# Asegurarse de que "Clasificacion" sea un factor
datos_imputados$Clasificacion <- factor(datos_imputados$Clasificacion)

# Verificar los niveles de "Clasificacion"
levels(datos_imputados$Clasificacion)

# Cargar el paquete caret
library(caret)

# Identificar las variables con varianza muy baja
vars_con_varianza_baja <- nearZeroVar(datos_imputados)

# Eliminar las variables con varianza baja del conjunto de datos
datos_sin_varianza_cero <- datos_imputados[, -vars_con_varianza_baja]

# Entrenar el modelo Naive Bayes con validación cruzada
modelo_nb_cv <- train(factor(Clasificacion) ~ . - SalePrice, data = datos_sin_varianza_cero, method = "naive_bayes", trControl = control)

# Mostrar el resumen del modelo
print(modelo_nb_cv)

# Realizar predicciones con el modelo cruzado en el conjunto de prueba
predicciones_cruzadas <- predict(modelo_nb_cv, newdata = test_imputado)

# Calcular la precisión con el modelo cruzado
precision_cruzada <- sum(predicciones_cruzadas == test_imputado$Clasificacion) / length(test_imputado$Clasificacion)
print(paste("Precisión con validación cruzada:", precision_cruzada))

#Inciso 10.

# Definir los parámetros a sintonizar
grid <- expand.grid(laplace = c(0, 0.5, 1), usekernel = c(TRUE, FALSE), adjust = TRUE)

# Realizar el ajuste de hiperparámetros
modelo_tune <- train(factor(Clasificacion) ~ . - SalePrice, data = datos_sin_varianza_cero, method = "naive_bayes", trControl = control, tuneGrid = grid)

# Mostrar los mejores parámetros encontrados
print(modelo_tune)

# Realizar predicciones con el modelo cruzado en el conjunto de prueba
predicciones_cruzadas_tuneadas <- predict(modelo_tune, newdata = test_imputado)

# Calcular la precisión con el modelo cruzado
precision_cruzada_tuneada <- sum(predicciones_cruzadas_tuneadas == test_imputado$Clasificacion) / length(test_imputado$Clasificacion)
print(paste("Precisión con validación cruzada ya tuneada:", precision_cruzada_tuneada))

# Comparar el rendimiento del modelo original con el modelo ajustado
print(paste("Precisión del modelo Naive Bayes original:", modelo_nb_cv$results$Accuracy))
print(paste("Precisión del modelo Naive Bayes con tuneo de hiperparámetros:", modelo_tune$results$Accuracy))
