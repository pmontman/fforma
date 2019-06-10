
FFORMA: Feature-based Forecast Model Averaging
==============================================

Introduction & Citation Info
----------------------------

The fforma package provides tools for forecasting using a model combination approach. It can be used for model averaging or model selection. It works by training a 'classifier' that learns to select/combine different forecast models.

More information about metalearning for forecasting, read/cite the paper:

-   [FFORMA: Feature-based Forecast Model Averaging (To appear in International Journal of Forecasting)](https://robjhyndman.com/publications/fforma/)

This package came out of the FFORMA method presented to the M4 forecasting competition, but has been improved and no longer can be used for reproducing results. For exact reproducibilty of results, check [the M4metalearning github repo](https://github.com/robjhyndman/M4metalearning). For empirical performance, the fforma package, not M4metalearning, should be used.

Installation
------------

Temporarily, as a workaround, a custom version of the `xgboost` package is required. You may install it manually from:

``` r
# install.packages("devtools")
devtools::install_github("pmontman/customxgboost")
```

Please note this if you use the latest version of the real xgboost package, *it will be overwritten.* We will patch this problom/workaround as soon as posssible.

Then the package can then be installed:

``` r
#install.packages("devtools")
devtools::install_github("pmontman/fforma")
```

Usage
-----

The package can be used easily with two main functions: `train_metalearning` and `forecast_metalearning`. Both functions work on a `list` of elements with a particular data structure: A time series and some meta-data. Basically, each element in this list has *at least* the component `$x` with a time series as a `ts` object, which is the series we want to forecast.

### Training FFORMA

The `train_metalearning` function will look for the component `$h` in the elements of the input list, where `$h` represents the desired prediction horizon. If not found, it will consider `h` to one seasonal period of the series. Then it substracts `h` observations from the time series `$x` and set them as true future values in the element `$xx`. Then the metalearning model is trained (takes a bit of time, see Paralellism). The output of the `train_metalearning` is the metalearning model, the training dataset (after the temporal crossvalidation) and the information about the training process. This output of the training process can be used to forecast with the `forecast_metalearning` function.

In the example, we will use a dataset of time series from the Mcomp package as training set, which already follows the required format (a list with elements having the `$x`. Additionally the `$h` is provided).

``` r
set.seed(1234)
library(fforma)
#The dataset of time series we want to forecast
ts_dataset <- Mcomp::M3[sample(length(Mcomp::M3), 30)]
#train!
fforma_fit <- train_metalearning(ts_dataset)
```

### Forecasting with FFORMA

The `forecast_ metalearning` takes a metaleaning model (the output of `train_metalearning` or equivalent) and a dataset of time series we want to forecast. This dataset is a list in the same format, though now the `$h` component if necessary. The dataset for forecasting can be the same as the one used for training (since it uses crossvalidation by temporal holdout for training).

``` r
fforma_forec <- forecast_metalearning(fforma_fit, ts_dataset)
```

Thats' it, two lines of code! If the dataset we forecast has the `$xx` component in its elements, fforma will use it as the 'true' future values of each series `$x` and calculate the OWA, MASE and SMAPE forecast errors.

`forecast_metalearning` outputs a dataset of time series similar to its input, but with the added forecasts in the component `$ff_meta_avg` of each element of the list.

``` r
#get the forecasts of the first series
fforma_forec$dataset[[1]]$ff_meta_avg
```

### Parallelism and Save/Restore progress

Forecasting with FFORMA can take a bit of time depending of the individual models that are going to be combined for forecasting and the size of the dataset. Parallelism through the `future` package is provided and the processing can be periodically saved to disk and resumed in the case of failure (like power outage, or an impending Windows update).

The user just needs to select the `future::plan` and then paralellism is handled transparently. More info about future plans/capabilities (here)\[<https://github.com/HenrikBengtsson/future>\].

``` r
#the user enables, in this case, basic multicore parallelism through several processes
future::plan(future::multiprocess)
#train with parallelism enabled, no changes to the code
fforma_fit <- train_metalearning(ts_dataset)
#forecast with parallelism enabled, no changes to the code
fforma_forec <- forecast_metalearning(fforma_fit, ts_dataset)
```

For saving intermediate results, `train_metalearning` and `forecast_metalearning` have the `save_foldername` parameter, which must be set to the name of the folder to save the intermediate results. If this parameter is set to `NULL`, no saving/resume is used. If `save_foldername` is set to an existing folder, the functions will try to resume the processing from the state saved in the folder. So the basic use is to launch `train_metalearning` or `test_metalearning` with a specific `save_foldername`, and if the process is interrupted, we launch them again with the same `save_foldername` vale an process will resume.

An important additional parameter to use with `chunk_size`, which indicates how many time series are processed between savings. If we set `chunk_size=1000`, the traing/forecast process will stop to save progress each 1000 series. Too large value for `chunk_size` will run risk of losing a lot of progress, too small will waste a lot of time saving to disk. An automatic guess of `chunk_size` is provided if `chunk_size=NULL`, but it is highly recommended that the users set it manually to their needs.

Saving can be combined with parallelism.

An example of saving to disk

``` r
#run with saving to disk (NOTE chunk_size=10 is too low!, just for example)
fforma_fit <- train_metalearning(ts_dataset, chunk_size = 10, save_foldername = "my_tmp_fforma")
#imagine that the powers goes of when series 14 is being processed...
#...
#... BOOM!
#...
# Now we want to resume!
#We just call use the same function call, now it will try to resume
#train_metalearning will start from series 11 if it finds
#the temp files in save_foldername
fforma_fit <- train_metalearning(ts_dataset, chunk_size = 10, save_foldername = "my_tmp_fforma")
```

### Forecast methods

The users can select which basic forecast methods are combined through fforma. The default is based on the fforma submission to the M4 competition [(see the reference)](https://robjhyndman.com/publications/fforma/)

### Combination by Model Averaging or Model Selection

The training can be fine-tuned towards either model selection or model averaging by setting the `objective` parameter in `train_metalearning` too either `"averaging"` (default) or `"selection"`.

``` r
fforma_fit <- train_metalearning(ts_dataset, objective = "selection")
```

### Advanced use

The package provides functions for manually tuning the training/forecasting processes. TO BE COMPLETED
