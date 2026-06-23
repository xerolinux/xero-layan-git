function getAttributeValue(node, attributeName) {
    if (node.attributes) {
        for (let i = 0; i < node.attributes.length; i++) {
            if (node.attributes[i].name === attributeName) {
                return node.attributes[i].value;
            }
        }
    }
    return "";
}

function getTextContent(node) {
    return node && node.firstChild ? node.firstChild.nodeValue : "";
}

// Removes inline tags that could break layout but don't have content
function cleanDescription(html) {
    if (!html) return "";

    var allowedTags = ["b", "strong", "i", "em", "u", "a", "p", "br", "ul", "ol", "li", "span", "strike", "s", "del", "sub", "sup", "code", "pre", "blockquote", "h1", "h2", "h3", "h4", "h5", "h6"];

    // Remove HTML comments
    html = html.replace(/<!--[\s\S]*?-->/g, "");

    // Regex to remove disallowed tags but keep content
    html = html.replace(/<\/?([a-zA-Z0-9]+)(?:\s[^>]*)?>/g, function (match, tagName) {
        tagName = tagName.toLowerCase();
        return allowedTags.includes(tagName) ? match : "";
    });

    return html.trim();
}

function fetchNews(rssUrl, callback) {
    var xhr = new XMLHttpRequest();
    xhr.responseType = "document";
    console.log("Fetching news from " + rssUrl);
    xhr.open("GET", rssUrl);

    xhr.onreadystatechange = function () {
        if (xhr.readyState === XMLHttpRequest.DONE) {
            if (xhr.status === 200) {
                var xmlDoc = xhr.responseXML;

                if (!xmlDoc || !xmlDoc.documentElement) {
                    callback([], "Failed to parse XML document");
                    return;
                }

                var newsArray = [];
                var feedTitle = "Unknown Feed";
                var root = xmlDoc.documentElement;

                if (root.nodeName === "rss") {
                    // --- RSS Feed ---
                    var channel = null;
                    var rootChildren = root.childNodes;
                    for (let i = 0; i < rootChildren.length; i++) {
                        if (rootChildren[i].nodeName === "channel") {
                            channel = rootChildren[i];
                            break;
                        }
                    }

                    if (!channel) {
                        callback([], "No <channel> element found in RSS feed");
                        return;
                    }

                    var titleNode = channel.firstChild;
                    while (titleNode) {
                        if (titleNode.nodeName === "title") {
                            feedTitle = getTextContent(titleNode);
                            break;
                        }
                        titleNode = titleNode.nextSibling;
                    }

                    var itemNode = channel.firstChild;
                    while (itemNode) {
                        if (itemNode.nodeName === "item") {
                            newsArray.push(parseRssItem(itemNode));
                        }
                        itemNode = itemNode.nextSibling;
                    }

                } else if (root.nodeName === "feed") {
                    // --- Atom Feed ---
                    var titleNode = root.firstChild;
                    while (titleNode) {
                        if (titleNode.nodeName === "title") {
                            feedTitle = getTextContent(titleNode);
                            break;
                        }
                        titleNode = titleNode.nextSibling;
                    }

                    var entryNode = root.firstChild;
                    while (entryNode) {
                        if (entryNode.nodeName === "entry") {
                            newsArray.push(parseAtomEntry(entryNode));
                        }
                        entryNode = entryNode.nextSibling;
                    }
                } else {
                    callback([], "Unsupported feed format: " + root.nodeName);
                    return;
                }

                if (newsArray.length === 0) {
                    callback([], "No news articles found in the feed.");
                } else {
                    callback({ url: rssUrl, title: feedTitle, items: newsArray }, "");
                }

            } else {
                callback([], "Failed to load RSS feed (HTTP Status " + xhr.status + ")");
            }
        }
    };

    xhr.send();
}

function parseRssItem(itemNode) {
    var title = "No title";
    var link = "#";
    var description = "No description";
    var pubDate = "No date";
    var imageUrl = "";

    var children = itemNode.childNodes;
    for (let i = 0; i < children.length; i++) {
        var child = children[i];
        switch (child.nodeName) {
            case "title":
                title = getTextContent(child);
                break;
            case "link":
                if (link === "#") link = getTextContent(child);
                break;
            case "description":
                description = cleanDescription(getTextContent(child));
                break;
            case "pubDate":
                pubDate = getTextContent(child);
                break;
            case "thumbnail":
            case "enclosure":
            case "content":
                imageUrl = getAttributeValue(child, "url");
                break;
            case "group":
                var mediaChild = child.firstChild;
                while (mediaChild) {
                    if (mediaChild.nodeName === "content") {
                        imageUrl = getAttributeValue(mediaChild, "url");
                        break;
                    }
                    mediaChild = mediaChild.nextSibling;
                }
                break;
        }
    }

    return { title, link, description, pubDate, imageUrl };
}

function parseAtomEntry(entryNode) {
    var title = "No title";
    var link = "#";
    var description = "No description";
    var pubDate = "No date";
    var imageUrl = "";

    var children = entryNode.childNodes;
    for (let i = 0; i < children.length; i++) {
        var child = children[i];
        switch (child.nodeName) {
            case "title":
                title = getTextContent(child);
                break;
            case "link":
                var rel = getAttributeValue(child, "rel");
                if (rel !== "self" && getAttributeValue(child, "href")) {
                    link = getAttributeValue(child, "href");
                }
                break;
            case "summary":
            case "content":
                description = cleanDescription(getTextContent(child));
                break;
            case "updated":
            case "published":
                pubDate = getTextContent(child);
                break;
            case "thumbnail":
            case "content":
                imageUrl = getAttributeValue(child, "url");
                break;
        }
    }

    return { title, link, description, pubDate, imageUrl };
}

function fetchAllFeeds(feedUrls, callback) {
    var allFeeds = [];
    var errors = [];
    var remaining = feedUrls.length;

    feedUrls.forEach(rssUrl => {
        fetchNews(rssUrl, (feedData, errorMessage) => {
            if (errorMessage) errors.push(`Error fetching ${rssUrl}: ${errorMessage}`);
            else allFeeds.push(feedData);

            if (--remaining === 0) callback(allFeeds, errors.length ? errors.join("\n") : "");
        });
    });
}
