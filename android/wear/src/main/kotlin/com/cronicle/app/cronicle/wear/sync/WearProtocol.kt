package com.cronicle.app.cronicle.wear.sync

/**
 * Shared protocol constants between the phone and watch apps. Any change here MUST be
 * mirrored in the phone-side `WearLibraryListenerService`.
 */
object WearProtocol {
    /** Watch → Phone: empty message asking the phone to publish a fresh snapshot. */
    const val PATH_REQUEST_SYNC = "/library/request_sync"

    /** Phone → Watch: DataItem at this path holds the JSON snapshot of in-progress items. */
    const val PATH_LIBRARY_ITEMS = "/library/items"

    /** Watch → Phone: action message (increment / complete). */
    const val PATH_ACTION = "/library/action"

    // DataItem keys
    const val KEY_ITEMS_JSON = "items_json"
    const val KEY_TIMESTAMP = "timestamp"

    // Action message JSON fields
    const val ACTION_INCREMENT = "increment"
    const val ACTION_COMPLETE = "complete"
}
