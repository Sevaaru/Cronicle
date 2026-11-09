package com.cronicle.app.cronicle.wear.sync

object WearProtocol {
    const val PATH_REQUEST_SYNC = "/library/request_sync"

    const val PATH_LIBRARY_ITEMS = "/library/items"

    const val PATH_ACTION = "/library/action"

    const val KEY_ITEMS_JSON = "items_json"
    const val KEY_TIMESTAMP = "timestamp"

    const val ACTION_INCREMENT = "increment"
    const val ACTION_COMPLETE = "complete"
}
